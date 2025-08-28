import { supabase } from '../lib/supabase';
import { storageService } from '../lib/storage';

export interface ProfileUpdateData {
  name?: string;
  phone?: string;
  address?: string;
  city?: string;
  state?: string;
  country?: string;
  company?: string;
  government_id?: string;
  ca_license?: string;
  verification_documents?: string[];
  profile_photo_url?: string;
}

export interface FileUploadResult {
  url: string;
  path: string;
  filename: string;
}

export class ProfileService {
  // Upload profile photo to verification-documents bucket (temporary solution)
  static async uploadProfilePhoto(file: File, userId: string, oldPhotoUrl?: string): Promise<FileUploadResult> {
    const fileExt = file.name.split('.').pop();
    const fileName = `${userId}/profile-photo-${Date.now()}.${fileExt}`;
    
    // Use verification-documents bucket temporarily until profile-photos bucket is created
    const result = await storageService.uploadFile(file, 'verification-documents', fileName);
    
    if (!result.success || !result.url) {
      throw new Error(`Error uploading profile photo: ${result.error}`);
    }

    // If upload successful and we have an old photo URL, delete the old file from storage
    if (oldPhotoUrl && result.success) {
      try {
        // Extract file path from old URL
        const oldPath = oldPhotoUrl.split('/').slice(-2).join('/'); // Get userId/filename part
        console.log('🗑️ Attempting to delete old profile photo:', oldPath);
        await this.deleteProfilePhoto(oldPath);
        console.log('✅ Old profile photo deleted from storage:', oldPath);
      } catch (deleteError) {
        console.warn('⚠️ Failed to delete old profile photo from storage:', deleteError);
        // Don't fail the upload if deletion fails, but log the warning
      }
    }

    return {
      url: result.url,
      path: fileName,
      filename: file.name
    };
  }

  // Upload verification documents using existing storage service
  static async uploadVerificationDocument(file: File, userId: string, documentType: string, oldUrl?: string): Promise<FileUploadResult> {
    try {
      console.log(`📄 Uploading ${documentType} for user:`, userId);
      
    // Get user email for consistent storage paths
    const { data: user } = await supabase
      .from('users')
      .select('email')
      .eq('id', userId)
      .single();
    
    if (!user?.email) {
      throw new Error('User email not found');
    }
    
    // Upload new file first - use email for consistent storage paths
    const result = await storageService.uploadVerificationDocument(file, user.email, documentType);
    
    if (!result.success || !result.url) {
      throw new Error(`Error uploading verification document: ${result.error}`);
    }

      // If upload successful and we have an old URL, delete the old file from storage
    if (oldUrl && result.success) {
      try {
        // Extract file path from old URL
        const oldPath = oldUrl.split('/').slice(-2).join('/'); // Get email/filename part
          console.log(`🗑️ Attempting to delete old ${documentType}:`, oldPath);
        await this.deleteVerificationDocument(oldPath);
          console.log(`✅ Old ${documentType} deleted from storage:`, oldPath);
      } catch (deleteError) {
          console.warn(`⚠️ Failed to delete old ${documentType} from storage:`, deleteError);
          // Don't fail the upload if deletion fails, but log the warning
        }
      }

      console.log(`✅ ${documentType} uploaded successfully:`, result.url);
    return {
      url: result.url,
      path: result.path || '',
      filename: file.name
    };
    } catch (error) {
      console.error(`❌ Error uploading ${documentType}:`, error);
      throw error;
    }
  }

  // Update user profile in the database
  static async updateProfile(userId: string, profileData: ProfileUpdateData): Promise<void> {
    try {
      console.log('💾 Updating user profile in database:', { userId, profileData });
      
          // Prepare update data (exclude cs_license until column is added to database)
      const updateData: any = {
        name: profileData.name,
        phone: profileData.phone,
        address: profileData.address,
        city: profileData.city,
        state: profileData.state,
        country: profileData.country,
        company: profileData.company,
        government_id: profileData.government_id,
        ca_license: profileData.ca_license,
        verification_documents: profileData.verification_documents,
        profile_photo_url: profileData.profile_photo_url,
        updated_at: new Date().toISOString()
      };

      // Only include cs_license if the column exists (for future use)
      // For now, CS licenses are stored in ca_license field
      // if (profileData.cs_license) {
      //   updateData.cs_license = profileData.cs_license;
      // }

      const { error } = await supabase
        .from('users')
        .update(updateData)
      .eq('id', userId);

    if (error) {
        console.error('❌ Database update error:', error);
      throw new Error(`Error updating profile: ${error.message}`);
      }
      
      console.log('✅ User profile successfully updated in database');
    } catch (error) {
      console.error('❌ Error in updateProfile:', error);
      throw error;
    }
  }

  // Get user profile from database
  static async getProfile(userId: string) {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      throw new Error(`Error fetching profile: ${error.message}`);
    }

    return data;
  }

  // Delete old verification documents using existing storage service
  static async deleteVerificationDocument(filePath: string): Promise<void> {
    try {
      console.log('🗑️ Deleting verification document from storage:', filePath);
      
    // Use existing storage service to delete files
    const result = await storageService.deleteFile('verification-documents', filePath);
    
    if (!result.success) {
        console.error('❌ Storage deletion failed:', result.error);
        throw new Error(`Error deleting verification document from storage: ${result.error}`);
      }
      
      console.log('✅ Verification document successfully deleted from storage:', filePath);
    } catch (error) {
      console.error('❌ Error in deleteVerificationDocument:', error);
      throw error;
    }
  }

  // Delete old profile photo using existing storage service
  static async deleteProfilePhoto(filePath: string): Promise<void> {
    try {
      console.log('🗑️ Deleting profile photo from storage:', filePath);
      
    // Use existing storage service to delete files
    const result = await storageService.deleteFile('verification-documents', filePath);
    
    if (!result.success) {
        console.error('❌ Storage deletion failed:', result.error);
        throw new Error(`Error deleting profile photo from storage: ${result.error}`);
      }
      
      console.log('✅ Profile photo successfully deleted from storage:', filePath);
    } catch (error) {
      console.error('❌ Error in deleteProfilePhoto:', error);
      throw error;
    }
  }

  // Replace verification document (upload new, delete old, update database)
  static async replaceVerificationDocument(file: File, userId: string, documentType: string, oldUrl?: string): Promise<FileUploadResult> {
    try {
      console.log(`🔄 Replacing ${documentType} for user:`, userId);
      
      // Upload new document first
      const uploadResult = await this.uploadVerificationDocument(file, userId, documentType, oldUrl);
      
      // Update database with new document URL
      const updateData: Partial<ProfileUpdateData> = {};
      
      // Set the appropriate field based on document type
      switch (documentType) {
        case 'government-id':
          updateData.government_id = uploadResult.url;
          break;
        case 'ca-license':
          updateData.ca_license = uploadResult.url;
          break;
        case 'cs-license':
          // CS licenses are stored in the ca_license field (existing working system)
          updateData.ca_license = uploadResult.url;
          console.log('✅ CS license stored in ca_license field (existing system)');
          break;
        case 'verification-documents':
          // For additional verification documents, we need to handle the array
          // This would require fetching current documents and updating the array
          break;
        default:
          console.warn(`⚠️ Unknown document type: ${documentType}`);
      }
      
      if (Object.keys(updateData).length > 0) {
        await this.updateProfile(userId, updateData);
      }
      
      // Clean up orphaned documents
      await this.cleanupOrphanedVerificationDocuments(userId, documentType);
      
      console.log(`✅ ${documentType} replacement completed successfully`);
      return uploadResult;
      
    } catch (error) {
      console.error(`❌ Error replacing ${documentType}:`, error);
      throw error;
    }
  }

  // Replace profile photo (upload new, delete old, update database)
  static async replaceProfilePhoto(file: File, userId: string, oldPhotoUrl?: string): Promise<FileUploadResult> {
    try {
      console.log('🔄 Replacing profile photo for user:', userId);
      
      // Upload new photo first
      const uploadResult = await this.uploadProfilePhoto(file, userId, oldPhotoUrl);
      
      // Update database with new photo URL
      await this.updateProfile(userId, {
        profile_photo_url: uploadResult.url
      });
      
      // Clean up orphaned photos
      await this.cleanupOrphanedProfilePhotos(userId);
      
      console.log('✅ Profile photo replacement completed successfully');
      return uploadResult;
      
    } catch (error) {
      console.error('❌ Error replacing profile photo:', error);
      throw error;
    }
  }

  // Clean up orphaned verification documents and ensure database consistency
  static async cleanupOrphanedVerificationDocuments(userId: string, documentType: string): Promise<void> {
    try {
      console.log(`🧹 Cleaning up orphaned ${documentType} for user:`, userId);
      
              // Get current user profile
        const { data: user, error: fetchError } = await supabase
          .from('users')
          .select('government_id, ca_license, cs_license, verification_documents')
          .eq('id', userId)
          .single();

      if (fetchError) {
        console.error('❌ Error fetching user profile for cleanup:', fetchError);
        return;
      }

      // Get user email for storage path
      const { data: userEmail } = await supabase
        .from('users')
        .select('email')
        .eq('id', userId)
        .single();

      if (!userEmail?.email) {
        console.error('❌ User email not found for cleanup');
        return;
      }

      // Check what files exist in storage for this user
      const { data: storageFiles } = await supabase.storage
        .from('verification-documents')
        .list(userEmail.email);

      if (storageFiles && storageFiles.length > 0) {
        let currentDocumentUrl = '';
        
        // Get current document URL based on type
        switch (documentType) {
          case 'government-id':
            currentDocumentUrl = user.government_id || '';
            break;
          case 'ca-license':
            currentDocumentUrl = user.ca_license || '';
            break;
          case 'cs-license':
            // CS licenses are stored in ca_license field
            currentDocumentUrl = user.ca_license || '';
            break;
          default:
            console.log(`ℹ️ No cleanup needed for document type: ${documentType}`);
            return;
        }

        if (!currentDocumentUrl) {
          console.log(`ℹ️ No current ${documentType} URL found, nothing to clean up`);
          return;
        }

        // Extract current filename from URL
        const currentFilename = currentDocumentUrl.split('/').slice(-1)[0];
        
        // Find orphaned documents of the same type
        const orphanedDocs = storageFiles.filter(file => {
          const isSameType = file.name.includes(documentType.replace('-', ''));
          const isNotCurrent = file.name !== currentFilename;
          return isSameType && isNotCurrent;
        });

        // Delete orphaned documents
        for (const doc of orphanedDocs) {
          try {
            const fullPath = `${userEmail.email}/${doc.name}`;
            console.log(`🗑️ Deleting orphaned ${documentType}:`, fullPath);
            await this.deleteVerificationDocument(fullPath);
          } catch (error) {
            console.warn(`⚠️ Failed to delete orphaned ${documentType}:`, doc.name, error);
          }
        }

        if (orphanedDocs.length > 0) {
          console.log(`✅ Cleaned up ${orphanedDocs.length} orphaned ${documentType} files`);
        }
      }
    } catch (error) {
      console.error(`❌ Error in cleanupOrphanedVerificationDocuments:`, error);
    }
  }

  // Clean up orphaned profile photos and ensure database consistency
  static async cleanupOrphanedProfilePhotos(userId: string): Promise<void> {
    try {
      console.log('🧹 Cleaning up orphaned profile photos for user:', userId);
      
      // Get current user profile
      const { data: user, error: fetchError } = await supabase
        .from('users')
        .select('profile_photo_url')
        .eq('id', userId)
        .single();

      if (fetchError) {
        console.error('❌ Error fetching user profile for cleanup:', fetchError);
        return;
      }

      if (!user?.profile_photo_url) {
        console.log('ℹ️ No profile photo URL found, nothing to clean up');
        return;
      }

      // Check if the file actually exists in storage
      const photoPath = user.profile_photo_url.split('/').slice(-2).join('/');
      const { data: storageFiles } = await supabase.storage
        .from('verification-documents')
        .list(userId);

      if (storageFiles && storageFiles.length > 0) {
        // Find profile photos for this user
        const profilePhotos = storageFiles.filter(file => 
          file.name.includes('profile-photo') && 
          file.name !== photoPath.split('/')[1] // Exclude current photo
        );

        // Delete orphaned profile photos
        for (const photo of profilePhotos) {
          try {
            const fullPath = `${userId}/${photo.name}`;
            console.log('🗑️ Deleting orphaned profile photo:', fullPath);
            await this.deleteProfilePhoto(fullPath);
          } catch (error) {
            console.warn('⚠️ Failed to delete orphaned photo:', photo.name, error);
          }
        }

        if (profilePhotos.length > 0) {
          console.log(`✅ Cleaned up ${profilePhotos.length} orphaned profile photos`);
        }
      }
    } catch (error) {
      console.error('❌ Error in cleanupOrphanedProfilePhotos:', error);
    }
  }
}
