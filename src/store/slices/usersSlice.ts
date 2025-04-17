import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { User, UserProfile } from '../../types';
import { supabase, getSupabaseErrorDetails } from '../../lib/supabase';
import { RootState } from '..';

interface UsersState {
  users: UserProfile[];
  selectedUser: UserProfile | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: UsersState = {
  users: [],
  selectedUser: null,
  isLoading: false,
  error: null,
};

// Function to check if the current user is an admin
const checkAdminPermission = async () => {
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    throw new Error('You must be logged in to manage users');
  }

  const { data: profileData, error: profileError } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', data.user.id)
    .single();

  if (profileError || !profileData || profileData.role !== 'admin') {
    throw new Error('You must be an admin to manage users');
  }
};

// Admin-only: Fetch all users
export const fetchUsers = createAsyncThunk(
  'users/fetchUsers',
  async (_, { rejectWithValue }) => {
    try {
      // First check if the current user is an admin
      await checkAdminPermission();

      // Get users from auth.users joined with profiles
      const { data: authUsers, error: authError } = await supabase
        .from('profiles')
        .select(`
          id,
          role,
          full_name,
          company,
          title,
          created_at,
          updated_at
        `)
        .order('created_at', { ascending: false });

      if (authError) {
        return rejectWithValue(authError.message);
      }

      return authUsers as UserProfile[];
    } catch (error) {
      return rejectWithValue(getSupabaseErrorDetails(error) || 'Failed to fetch users');
    }
  }
);

// Admin-only: Fetch single user by ID
export const fetchUserById = createAsyncThunk(
  'users/fetchUserById',
  async (userId: string, { rejectWithValue }) => {
    try {
      // First check if the current user is an admin
      await checkAdminPermission();

      // Get user from profiles table
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) {
        return rejectWithValue(error.message);
      }

      return data as UserProfile;
    } catch (error) {
      return rejectWithValue(getSupabaseErrorDetails(error) || 'Failed to fetch user');
    }
  }
);

// Admin-only: Update user role
export const updateUserRole = createAsyncThunk(
  'users/updateUserRole',
  async ({ userId, role }: { userId: string; role: string }, { rejectWithValue }) => {
    try {
      // First check if the current user is an admin
      await checkAdminPermission();

      // Make sure the role is valid
      if (role !== 'admin' && role !== 'user') {
        return rejectWithValue('Invalid role. Must be "admin" or "user"');
      }

      // For promoting to admin, use the RPC function
      if (role === 'admin') {
        // First get the user's email
        const { data: userData, error: userError } = await supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .single();

        if (userError || !userData) {
          return rejectWithValue('User not found');
        }

        // Get the user's email from auth.users
        const { data: authData, error: authError } = await supabase.auth.admin.getUserById(userId);
        
        if (authError || !authData?.user) {
          return rejectWithValue('Failed to get user details');
        }

        // Call the promote_to_admin RPC function
        const { data, error } = await supabase.rpc(
          'promote_to_admin',
          { user_email: authData.user.email }
        );

        if (error) {
          return rejectWithValue(error.message);
        }
      } else {
        // For demoting to regular user, use the RPC function
        const { data: authData, error: authError } = await supabase.auth.admin.getUserById(userId);
        
        if (authError || !authData?.user) {
          return rejectWithValue('Failed to get user details');
        }

        // Call the demote_from_admin RPC function
        const { data, error } = await supabase.rpc(
          'demote_from_admin',
          { user_email: authData.user.email }
        );

        if (error) {
          return rejectWithValue(error.message);
        }
      }

      // Fetch the updated user profile
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) {
        return rejectWithValue(error.message);
      }

      return data as UserProfile;
    } catch (error) {
      return rejectWithValue(getSupabaseErrorDetails(error) || 'Failed to update user role');
    }
  }
);

// Admin-only: Delete user (this should be used with caution)
export const deleteUser = createAsyncThunk(
  'users/deleteUser',
  async (userId: string, { rejectWithValue }) => {
    try {
      // First check if the current user is an admin
      await checkAdminPermission();

      // Check that we're not deleting the current user
      const { data: currentUser } = await supabase.auth.getUser();
      if (currentUser.user?.id === userId) {
        return rejectWithValue('You cannot delete your own account');
      }

      // Delete user from auth
      const { error } = await supabase.auth.admin.deleteUser(userId);

      if (error) {
        return rejectWithValue(error.message);
      }

      return userId;
    } catch (error) {
      return rejectWithValue(getSupabaseErrorDetails(error) || 'Failed to delete user');
    }
  }
);

const usersSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {
    clearSelectedUser: (state) => {
      state.selectedUser = null;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch Users
      .addCase(fetchUsers.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchUsers.fulfilled, (state, action: PayloadAction<UserProfile[]>) => {
        state.isLoading = false;
        state.users = action.payload;
      })
      .addCase(fetchUsers.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      // Fetch User By Id
      .addCase(fetchUserById.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchUserById.fulfilled, (state, action: PayloadAction<UserProfile>) => {
        state.isLoading = false;
        state.selectedUser = action.payload;
      })
      .addCase(fetchUserById.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      // Update User Role
      .addCase(updateUserRole.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(updateUserRole.fulfilled, (state, action: PayloadAction<UserProfile>) => {
        state.isLoading = false;
        // Update the selected user
        state.selectedUser = action.payload;
        // Also update the user in the users array
        state.users = state.users.map((user) =>
          user.id === action.payload.id ? action.payload : user
        );
      })
      .addCase(updateUserRole.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      // Delete User
      .addCase(deleteUser.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(deleteUser.fulfilled, (state, action: PayloadAction<string>) => {
        state.isLoading = false;
        // Remove the user from the users array
        state.users = state.users.filter((user) => user.id !== action.payload);
        // Clear selected user if it's the deleted user
        if (state.selectedUser && state.selectedUser.id === action.payload) {
          state.selectedUser = null;
        }
      })
      .addCase(deleteUser.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearSelectedUser, clearError } = usersSlice.actions;

// Selectors
export const selectUsers = (state: RootState) => state.users.users;
export const selectSelectedUser = (state: RootState) => state.users.selectedUser;
export const selectUsersLoading = (state: RootState) => state.users.isLoading;
export const selectUsersError = (state: RootState) => state.users.error;

export default usersSlice.reducer;
