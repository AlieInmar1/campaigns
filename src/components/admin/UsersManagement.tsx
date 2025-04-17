import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useAppDispatch, useAppSelector } from '../../hooks';
import { fetchUsers, updateUserRole, deleteUser, selectUsers, selectUsersLoading, selectUsersError } from '../../store/slices/usersSlice';
import { addNotification } from '../../store/slices/uiSlice';
import { UserProfile } from '../../types';
import { Shield, ShieldAlert, Trash2, User } from 'lucide-react';

const UsersManagement: React.FC = () => {
  const dispatch = useAppDispatch();
  const users = useAppSelector(selectUsers);
  const isLoading = useAppSelector(selectUsersLoading);
  const error = useAppSelector(selectUsersError);
  const currentUser = useAppSelector(state => state.auth.user);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);

  useEffect(() => {
    dispatch(fetchUsers());
  }, [dispatch]);

  const handlePromoteUser = async (userId: string) => {
    try {
      await dispatch(updateUserRole({ userId, role: 'admin' })).unwrap();
      dispatch(addNotification({
        type: 'success',
        message: 'User promoted to admin successfully',
        duration: 5000
      }));
    } catch (error) {
      dispatch(addNotification({
        type: 'error',
        message: `Failed to promote user: ${error}`,
        duration: 5000
      }));
    }
  };

  const handleDemoteUser = async (userId: string) => {
    try {
      await dispatch(updateUserRole({ userId, role: 'user' })).unwrap();
      dispatch(addNotification({
        type: 'success',
        message: 'User demoted to regular user successfully',
        duration: 5000
      }));
    } catch (error) {
      dispatch(addNotification({
        type: 'error',
        message: `Failed to demote user: ${error}`,
        duration: 5000
      }));
    }
  };

  const handleDeleteUser = async (userId: string) => {
    try {
      await dispatch(deleteUser(userId)).unwrap();
      setConfirmDelete(null);
      dispatch(addNotification({
        type: 'success',
        message: 'User deleted successfully',
        duration: 5000
      }));
    } catch (error) {
      dispatch(addNotification({
        type: 'error',
        message: `Failed to delete user: ${error}`,
        duration: 5000
      }));
    }
  };

  if (!currentUser?.isAdmin) {
    return (
      <div className="p-6 text-center">
        <h1 className="text-2xl font-bold text-gray-800 mb-4">Access Denied</h1>
        <p className="text-gray-600">You must be an admin to access this page.</p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="p-6 text-center">
        <p className="text-gray-600">Loading users...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6 text-center">
        <h1 className="text-2xl font-bold text-red-600 mb-4">Error</h1>
        <p className="text-gray-600">{error}</p>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800">User Management</h1>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                User
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Created
              </th>
              <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {users.map((user: UserProfile) => (
              <tr key={user.id} className={user.id === currentUser.id ? 'bg-blue-50' : ''}>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <div className="flex-shrink-0 h-10 w-10 bg-gray-200 rounded-full flex items-center justify-center">
                      <User className="h-5 w-5 text-gray-500" />
                    </div>
                    <div className="ml-4">
                      <div className="text-sm font-medium text-gray-900">
                        {user.full_name || 'No Name'}
                      </div>
                      <div className="text-sm text-gray-500">
                        {user.id === currentUser.id ? `${user.id} (You)` : user.id}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    user.role === 'admin' ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'
                  }`}>
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {new Date(user.created_at || '').toLocaleDateString()}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  {user.id !== currentUser.id && (
                    <div className="flex justify-end gap-2">
                      {user.role === 'admin' ? (
                        <button
                          onClick={() => handleDemoteUser(user.id)}
                          className="text-indigo-600 hover:text-indigo-900 p-1 rounded hover:bg-gray-100"
                          title="Demote to user"
                        >
                          <User className="h-5 w-5" />
                        </button>
                      ) : (
                        <button
                          onClick={() => handlePromoteUser(user.id)}
                          className="text-indigo-600 hover:text-indigo-900 p-1 rounded hover:bg-gray-100"
                          title="Promote to admin"
                        >
                          <Shield className="h-5 w-5" />
                        </button>
                      )}
                      
                      {confirmDelete === user.id ? (
                        <div className="flex gap-1">
                          <button
                            onClick={() => handleDeleteUser(user.id)}
                            className="text-red-600 hover:text-red-900 p-1 rounded hover:bg-red-100"
                            title="Confirm delete"
                          >
                            <Trash2 className="h-5 w-5" />
                          </button>
                          <button
                            onClick={() => setConfirmDelete(null)}
                            className="text-gray-600 hover:text-gray-900 p-1 rounded hover:bg-gray-100"
                            title="Cancel"
                          >
                            ✕
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => setConfirmDelete(user.id)}
                          className="text-gray-600 hover:text-red-900 p-1 rounded hover:bg-gray-100"
                          title="Delete user"
                        >
                          <Trash2 className="h-5 w-5" />
                        </button>
                      )}
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default UsersManagement;
