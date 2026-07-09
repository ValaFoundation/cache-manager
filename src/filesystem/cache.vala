namespace ValaFoundation.CacheManager.Filesystem {
    using ValaFoundation.CacheManager;
    using Gee;

    public class Cache : Object, CacheInterface {
        private HashMap<string, CacheItem> items;
        private RWLock rw_lock;
        private string directory_path;

        public Cache (string? directory_path = null) {
            this.items = new HashMap<string, CacheItem> ();
            this.rw_lock = RWLock ();
            this.directory_path = directory_path ?? Path.build_filename (Environment.get_user_cache_dir (), "vala-foundation-cache-manager");
            this.ensure_directory_exists ();
        }

        public CacheItemInterface? getItem (string key) {
            this.rw_lock.reader_lock ();
            CacheItem? item = this.items.get (key);
            this.rw_lock.reader_unlock ();
            if (item != null) {
                return item;
            }

            CacheItem? loaded = this.load_item_from_disk (key);
            if (loaded == null) {
                return null;
            }

            this.rw_lock.writer_lock ();
            this.items.set (key, loaded);
            this.rw_lock.writer_unlock ();
            return loaded;
        }

        public CacheItemInterface[] getItems (string[] keys) {
            var result = new ArrayList<CacheItemInterface> ();
            foreach (string key in keys) {
                CacheItemInterface? item = this.getItem (key);
                if (item != null) {
                    result.add (item);
                }
            }

            CacheItemInterface[] out = new CacheItemInterface[result.size];
            int i = 0;
            foreach (CacheItemInterface item in result) {
                out[i++] = item;
            }
            return out;
        }

        public bool hasItem (string key) {
            CacheItemInterface? item = this.getItem (key);
            if (item == null) {
                return false;
            }

            return item.IsHit ();
        }

        public bool clear () {
            this.rw_lock.writer_lock ();
            this.items = new HashMap<string, CacheItem> ();
            this.rw_lock.writer_unlock ();

            try {
                var dir = Dir.open (this.directory_path, 0);
                string? name;
                while ((name = dir.read_name ()) != null) {
                    string path = Path.build_filename (this.directory_path, name);
                    if (FileUtils.test (path, FileTest.IS_REGULAR)) {
                        FileUtils.remove (path);
                    }
                }
            } catch (FileError e) {
                return false;
            }

            return true;
        }

        public bool deleteItem (string key) {
            this.rw_lock.writer_lock ();
            this.items.unset (key);
            this.rw_lock.writer_unlock ();

            string path = this.file_path_for_key (key);
            if (!FileUtils.test (path, FileTest.EXISTS)) {
                return true;
            }

            return FileUtils.remove (path) == 0;
        }

        public bool deleteItems (string[] keys) {
            bool ok = true;
            foreach (string key in keys) {
                if (!this.deleteItem (key)) {
                    ok = false;
                }
            }
            return ok;
        }

        public bool save (CacheItemInterface item) {
            CacheItem? filesystem_item = item as CacheItem;
            if (filesystem_item == null) {
                return false;
            }

            this.rw_lock.writer_lock ();
            this.items.set (filesystem_item.getKey (), filesystem_item);
            this.rw_lock.writer_unlock ();

            return this.persist_item_to_disk (filesystem_item);
        }

        public bool saveItems (CacheItemInterface[] items) {
            foreach (CacheItemInterface item in items) {
                if (!this.save (item)) {
                    return false;
                }
            }

            return true;
        }

        public bool saveDeferred (CacheItemInterface item) {
            return this.save (item);
        }

        public bool commit () {
            return true;
        }

        private void ensure_directory_exists () {
            DirUtils.create_with_parents (this.directory_path, 0755);
        }

        private string file_path_for_key (string key) {
            string hashed = Checksum.compute_for_string (ChecksumType.SHA256, key);
            return Path.build_filename (this.directory_path, hashed + ".cache");
        }

        private bool persist_item_to_disk (CacheItem item) {
            this.ensure_directory_exists ();
            var key_file = new KeyFile ();
            if (!item.to_key_file (key_file)) {
                return false;
            }

            size_t length = 0;
            string data = key_file.to_data (out length);

            try {
                FileUtils.set_contents (this.file_path_for_key (item.getKey ()), data, (ssize_t) length);
                return true;
            } catch (FileError e) {
                return false;
            }
        }

        private CacheItem? load_item_from_disk (string key) {
            string path = this.file_path_for_key (key);
            if (!FileUtils.test (path, FileTest.EXISTS)) {
                return null;
            }

            string data;
            size_t length;

            try {
                FileUtils.get_contents (path, out data, out length);
                var key_file = new KeyFile ();
                key_file.load_from_data (data, data.length, KeyFileFlags.NONE);
                CacheItem? parsed = CacheItem.from_key_file (key_file);
                if (parsed == null) {
                    return null;
                }

                if (parsed.getKey () != key) {
                    return null;
                }

                return parsed;
            } catch (Error e) {
                return null;
            }
        }
    }
}
