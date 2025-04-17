/**
 * Provider interface
 */
export interface Provider {
  id: string;
  specialty: string;
  geographic_area: string;
  prescribing_volume: 'high' | 'medium' | 'low';
  practice_size: 'solo' | 'small' | 'medium' | 'large' | 'hospital';
  created_at?: string;
  updated_at?: string;
}

/**
 * Medication interface
 */
export interface Medication {
  id: string;
  name: string;
  category: string;
  description?: string;
  created_at?: string;
  updated_at?: string;
}

/**
 * Campaign interface
 */
export interface Campaign {
  id: string;
  name: string;
  description?: string; // Added description field
  status: 'draft' | 'in_progress' | 'completed' | 'cancelled' | 'active' | 'scheduled';
  created_by: string;
  created_at: string;
  updated_at?: string;
  start_date: string;
  end_date: string;
  target_medication_id?: string;
  target_specialty?: string;
  target_geographic_area?: string;
  targeting_metadata?: Record<string, any>;
}
