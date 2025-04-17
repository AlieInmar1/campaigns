import { Provider } from './index';

export interface ProviderListState {
  allProviders: Provider[];
  filteredProviders: Provider[];
  matchingCount: number;
  isLoading: boolean;
  loadingProgress: number;
  error?: string;
}

export interface ProviderFilterCriteria {
  category?: string;
  includedMedications?: string[];
  excludedMedications?: string[];
  specialties?: string[];
  regions?: string[];
}
