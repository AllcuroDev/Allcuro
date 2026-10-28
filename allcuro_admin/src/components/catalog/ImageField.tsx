import React, { useState } from 'react';
import { ImagePlus, Trash2 } from 'lucide-react';
import { uploadCatalogImage } from '../../lib/catalog';

interface ImageFieldProps {
  label: string;
  hint: string;
  folder: 'services' | 'categories';
  name: string;
  value: string | null;
  onChange: (url: string | null) => void;
  onBusy: (busy: boolean) => void;
}

/** Logo picker: uploads to Storage straight away and hands back the public URL. */
export const ImageField: React.FC<ImageFieldProps> = ({
  label,
  hint,
  folder,
  name,
  value,
  onChange,
  onBusy,
}) => {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const upload = async (file: File) => {
    if (file.size > 512 * 1024) {
      setError('Image is over 512 KB — export it smaller (256×256 WebP is ideal).');
      return;
    }
    setUploading(true);
    onBusy(true);
    setError(null);
    try {
      onChange(await uploadCatalogImage(folder, name, file));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Upload failed');
    }
    setUploading(false);
    onBusy(false);
  };

  return (
    <div className="catalog-field is-wide">
      <span>{label}</span>
      <div className="catalog-image-row">
        <div className="catalog-logo-preview">
          {value ? <img src={value} alt="" /> : <span>No logo</span>}
        </div>
        <div className="catalog-image-actions">
          <label className="btn-sm-outline catalog-upload">
            <ImagePlus size={13} />
            {uploading ? 'Uploading…' : value ? 'Replace logo' : 'Upload logo'}
            <input
              type="file"
              accept="image/png,image/webp,image/jpeg,image/svg+xml"
              hidden
              disabled={uploading}
              onChange={(e) => {
                const file = e.target.files?.[0];
                e.target.value = '';
                if (file) upload(file);
              }}
            />
          </label>
          {value && (
            <button type="button" className="btn-sm-outline" onClick={() => onChange(null)}>
              <Trash2 size={13} /> Remove
            </button>
          )}
          <small>{hint}</small>
        </div>
      </div>
      {error && <small className="is-error">{error}</small>}
    </div>
  );
};
