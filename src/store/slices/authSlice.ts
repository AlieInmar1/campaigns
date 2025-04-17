import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { User, UserProfile } from '../../types';
import { supabase, getSupabaseErrorDetails } from '../../lib/supabase';

// Function to copy sample data for a new user
const copySampleData = async (userId: string) => {
  try {
    // First check if user already has campaigns
    const { data: existingCampaigns } = await supabase
      .from('campaigns')
      .select('id')
      .eq('user_id', userId)
      .limit(1);
    
    // Only copy sample data if user has no campaigns
    if (!existingCampaigns || existingCampaigns.length === 0) {
      console.log('New user detected, copying sample data');
      
      // Call our RPC function to copy sample data
      const { data, error } = await supabase.rpc(
        'copy_sample_data_for_new_user', 
        { p_user_id: userId }
      );
      
      if (error) {
        console.error('Error copying sample data:', error);
      } else {
        console.log('Successfully copied sample data for new user');
      }
    } else {
      console.log('User already has campaigns, not copying sample data');
    }
  } catch (error) {
    console.error('Error in sample data copy process:', error);
  }
};

interface AuthState {
  user: User | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  isLoading: false,
  error: null,
};

export const signIn = createAsyncThunk(
  'auth/signIn',
  async ({ email, password }: { email: string; password: string }, { rejectWithValue }) => {
    try {
      console.log('Signing in with:', { email, password: '********' });
      
      // Enhanced sign-in with better error handling
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        console.error('Sign-in error:', error);
        return rejectWithValue(getSupabaseErrorDetails(error));
      }

      if (!data.user) {
        console.error('Sign-in successful but no user returned');
        return rejectWithValue('Authentication successful but user data is missing');
      }

      console.log('Sign-in successful:', data.user.id);
      
      // Copy sample data for the user if they don't have any campaigns yet
      await copySampleData(data.user.id);
      
      // Fetch user profile to get role information
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', data.user.id)
        .single();
      
      if (profileError) {
        console.warn('Could not fetch user profile:', profileError);
      }
      
      // Create user object with profile information
      const user: User = {
        id: data.user.id,
        email: data.user.email || '',
        // Use profile data if available, otherwise default to 'user' role
        role: profileData?.role || 'user',
        fullName: profileData?.full_name,
        company: profileData?.company,
        title: profileData?.title,
        // Helper flag for easy admin checks
        isAdmin: profileData?.role === 'admin'
      };
      
      return user;
    } catch (error) {
      console.error('Unexpected error during sign-in:', error);
      return rejectWithValue(getSupabaseErrorDetails(error) || 'Failed to sign in. Please try again.');
    }
  }
);

export const signUp = createAsyncThunk(
  'auth/signUp',
  async ({ email, password }: { email: string; password: string }, { rejectWithValue }) => {
    try {
      console.log('Signing up with:', { email, password: '********' });
      
      // Validate inputs before sending to API
      if (!email || !password) {
        return rejectWithValue('Email and password are required');
      }

      if (password.length < 6) {
        return rejectWithValue('Password must be at least 6 characters');
      }

      // Enhanced signup without email verification
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          // Make sure data is properly formatted
          data: {
            email: email,
          }
        }
      });

      if (error) {
        console.error('Sign-up error:', error);
        return rejectWithValue(getSupabaseErrorDetails(error));
      }

      if (!data.user) {
        console.error('Sign-up successful but no user returned');
        return rejectWithValue('Account created but user data is missing');
      }

      console.log('Sign-up successful:', data.user.id);
      
      // Ensure the user has a profile (using our new backup function)
      try {
        const { error: profileCreationError } = await supabase.rpc(
          'ensure_user_profile',
          { 
            user_id: data.user.id,
            user_role: 'user', 
            user_full_name: '' 
          }
        );
        
        if (profileCreationError) {
          console.warn('Error ensuring user profile via RPC:', profileCreationError);
        }
      } catch (profileError) {
        console.warn('Exception ensuring user profile:', profileError);
      }
      
      // Copy sample data for new users on signup
      await copySampleData(data.user.id);
      
      // Fetch user profile to get role information
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', data.user.id)
        .single();
      
      if (profileError) {
        console.warn('Could not fetch user profile after signup:', profileError);
      }
      
      // Create user object with profile information
      const user: User = {
        id: data.user.id,
        email: data.user.email || '',
        // Use profile data if available, otherwise default to 'user' role
        role: profileData?.role || 'user',
        fullName: profileData?.full_name,
        company: profileData?.company,
        title: profileData?.title,
        // Helper flag for easy admin checks
        isAdmin: profileData?.role === 'admin'
      };
      
      return user;
    } catch (error) {
      console.error('Unexpected error during sign-up:', error);
      return rejectWithValue(getSupabaseErrorDetails(error) || 'Failed to sign up. Please try again.');
    }
  }
);

export const signOut = createAsyncThunk(
  'auth/signOut',
  async (_, { rejectWithValue }) => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        return rejectWithValue(error.message);
      }
      return null;
    } catch (error) {
      return rejectWithValue('Failed to sign out. Please try again.');
    }
  }
);

export const getCurrentUser = createAsyncThunk(
  'auth/getCurrentUser',
  async (_, { rejectWithValue }) => {
    try {
      const { data, error } = await supabase.auth.getUser();
      
      if (error) {
        return rejectWithValue(error.message);
      }

      if (data.user) {
        // Also check for sample data when resuming session
        await copySampleData(data.user.id);
        
        // Fetch user profile to get role information
        const { data: profileData, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', data.user.id)
          .single();
        
        if (profileError) {
          console.warn('Could not fetch user profile on session restore:', profileError);
        }
        
        // Create user object with profile information
        const user: User = {
          id: data.user.id,
          email: data.user.email || '',
          // Use profile data if available, otherwise default to 'user' role
          role: profileData?.role || 'user',
          fullName: profileData?.full_name,
          company: profileData?.company,
          title: profileData?.title,
          // Helper flag for easy admin checks
          isAdmin: profileData?.role === 'admin'
        };
        
        return user;
      }
      
      return null;
    } catch (error) {
      return rejectWithValue('Failed to get current user.');
    }
  }
);

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Sign In
      .addCase(signIn.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(signIn.fulfilled, (state, action: PayloadAction<User | null>) => {
        state.isLoading = false;
        state.user = action.payload;
      })
      .addCase(signIn.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      // Sign Up
      .addCase(signUp.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(signUp.fulfilled, (state, action: PayloadAction<User | null>) => {
        state.isLoading = false;
        // Automatically set the user state after successful signup
        state.user = action.payload;
      })
      .addCase(signUp.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      // Sign Out
      .addCase(signOut.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(signOut.fulfilled, (state) => {
        state.isLoading = false;
        state.user = null;
      })
      .addCase(signOut.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      // Get Current User
      .addCase(getCurrentUser.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(getCurrentUser.fulfilled, (state, action: PayloadAction<User | null>) => {
        state.isLoading = false;
        state.user = action.payload;
      })
      .addCase(getCurrentUser.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearError } = authSlice.actions;
export default authSlice.reducer;
