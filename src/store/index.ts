import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import campaignReducer from './slices/campaignSlice';
import campaignResultsReducer from './slices/campaignResultsSlice';
import uiReducer from './slices/uiSlice';
import providerReducer from './slices/providerSlice';
import referenceDataReducer from './slices/referenceDataSlice';
import usersReducer from './slices/usersSlice';

// Import specific actions and selectors from each slice
import { addNotification, removeNotification, clearNotifications, toggleSidebar } from './slices/uiSlice';
import { getCurrentUser, signOut, clearError as clearAuthError } from './slices/authSlice';
import { 
  fetchCampaigns, createCampaign, updateCampaign, deleteCampaign, 
  fetchCampaignById, fetchCampaignResults, clearCurrentCampaign,
  setCampaignFilters, clearCampaignFilters, clearError as clearCampaignError
} from './slices/campaignSlice';
import { 
  generateAndStoreResults, 
  storeScriptLiftData, 
  clearScriptLiftData 
} from './slices/campaignResultsSlice';
import {
  fetchFilteredProviders, updateFilterState, updateQueryExpression,
  toggleAndLogic, clearError as clearProviderError
} from './slices/providerSlice';
import {
  fetchAllReferenceData, selectConditions, selectMedications,
  selectSpecialties, selectGeographicRegions, clearError as clearReferenceDataError
} from './slices/referenceDataSlice';
import {
  fetchUsers, fetchUserById, updateUserRole, deleteUser,
  clearSelectedUser, clearError as clearUsersError,
  selectUsers, selectSelectedUser, selectUsersLoading, selectUsersError
} from './slices/usersSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    campaigns: campaignReducer,
    campaignResults: campaignResultsReducer,
    ui: uiReducer,
    providers: providerReducer,
    referenceData: referenceDataReducer,
    users: usersReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

// Re-export all actions and selectors
export {
  // UI Actions
  addNotification,
  removeNotification,
  clearNotifications,
  toggleSidebar,
  
  // Auth Actions
  getCurrentUser,
  signOut,
  clearAuthError,
  
  // Campaign Actions
  fetchCampaigns,
  createCampaign,
  updateCampaign,
  deleteCampaign,
  fetchCampaignById,
  fetchCampaignResults,
  clearCurrentCampaign,
  setCampaignFilters,
  clearCampaignFilters,
  clearCampaignError,
  
  // Campaign Results Actions
  generateAndStoreResults,
  storeScriptLiftData,
  clearScriptLiftData,
  
  // Provider Actions
  fetchFilteredProviders,
  updateFilterState,
  updateQueryExpression,
  toggleAndLogic,
  clearProviderError,
  
  // Reference Data Actions
  fetchAllReferenceData,
  selectConditions,
  selectMedications,
  selectSpecialties,
  selectGeographicRegions,
  clearReferenceDataError,
  
  // Users Management Actions and Selectors
  fetchUsers,
  fetchUserById,
  updateUserRole,
  deleteUser,
  clearSelectedUser,
  clearUsersError,
  selectUsers,
  selectSelectedUser,
  selectUsersLoading,
  selectUsersError
};
