# Admin Access and User Roles

This document describes the implementation of role-based access control in the Healthcare Campaign Manager application.

## Overview

The system now supports different user roles, with an initial implementation of two roles:
- `user` - Standard users with access to their own campaigns and basic functionality
- `admin` - Administrators with additional privileges such as user management

## Database Implementation

The implementation uses a `profiles` table in Supabase to store role information and user profile data:

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'user',
  full_name VARCHAR(255),
  company VARCHAR(255),
  title VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### Security Implementation

1. **Row Level Security (RLS)** - The profiles table uses RLS to protect user data:
   - Users can only view and edit their own profiles (except role)
   - Only admins can change user roles

2. **Helper Functions** - Admin-only functions to promote and demote users:
   - `promote_to_admin(user_email TEXT)` - Make a user an admin
   - `demote_from_admin(user_email TEXT)` - Remove admin privileges

3. **Automatic Profile Creation** - A database trigger ensures every new user gets a profile:
   ```sql
   CREATE TRIGGER create_profile_after_signup
   AFTER INSERT ON auth.users
   FOR EACH ROW EXECUTE FUNCTION public.create_profile_for_user();
   ```

## Frontend Implementation

### User Authentication

The authentication flow has been enhanced to fetch profile information and determine user roles:
- On sign-in, sign-up, and session restoration, the user's profile is fetched
- The `isAdmin` flag is added to the user object for simple permission checks

### Admin Interface

A new admin section has been added with the following features:
- User management interface at `/admin/users`
- Admin-only sidebar navigation that only appears for admin users
- Role management UI to promote/demote users

### User Profile Types

The TypeScript type definitions have been extended:

```typescript
// Basic user with auth info and role
export interface User {
  id: string;
  email: string;
  role?: string;
  fullName?: string;
  company?: string;
  title?: string;
  isAdmin?: boolean;
}

// Database user profile
export interface UserProfile {
  id: string;
  role: string;
  full_name?: string;
  company?: string;
  title?: string;
  created_at?: string;
  updated_at?: string;
}
```

## User Management Component

The `UsersManagement` component allows administrators to:
1. View all users in the system
2. Promote regular users to admin role
3. Demote admins to regular user role (with safeguards to prevent removing the last admin)
4. Delete users (with confirmation and self-deletion prevention)

## Role-Based UI

The application includes conditional rendering based on user roles:
- The admin section in the sidebar only appears for users with the admin role
- The user management page has access control to prevent non-admin access
- Components can check `user.isAdmin` to conditionally render admin-only features

## Initial Admin Assignment

The migration sets up an initial admin user:

```sql
UPDATE public.profiles 
SET role = 'admin' 
WHERE id IN (
  SELECT id FROM auth.users WHERE email = 'aliecohen+2@gmail.com'
);
```

This ensures there's at least one admin user in the system to bootstrap the user management functionality.
