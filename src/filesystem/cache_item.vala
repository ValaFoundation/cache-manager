namespace ValaFoundation.CacheManager.Filesystem {
    using ValaFoundation.CacheManager;

    public class CacheItem : Object, CacheItemInterface {
        private const string KEY_GROUP = "item";

        protected bool is_hit;
        protected string key;
        protected Value? value;
        protected int ttl;
        protected bool keep_TTL;
        protected int expiration_timestamp;

        public CacheItem (string key, Value? value = null, int ttl = 0) {
            this.key = key;
            this.value = value;
            this.ttl = ttl;
            this.is_hit = false;
            this.keep_TTL = false;
            this.expiration_timestamp = 0;
        }

        public string getKey () {
            return this.key;
        }

        public Value? getValue () {
            if (!this.IsHit ()) {
                return null;
            }

            return this.value;
        }

        public bool IsHit () {
            if (this.keep_TTL) {
                return true;
            }

            if (!this.is_hit) {
                return false;
            }

            if (this.expiration_timestamp <= 0) {
                return true;
            }

            return this.expiration_timestamp > (int) (new GLib.DateTime.now_utc ()).to_unix ();
        }

        public CacheItemInterface setValue (Value? value, int ttl = 0) {
            this.value = value;
            this.is_hit = true;
            this.expireAfter (ttl);
            return this;
        }

        public CacheItemInterface expireAfter (int ttl) {
            this.ttl = ttl;

            if (ttl == TTL_INFINITE) {
                this.keep_TTL = true;
                this.is_hit = true;
                this.expiration_timestamp = 0;
                return this;
            }

            this.keep_TTL = false;

            if (ttl <= 0) {
                this.expiration_timestamp = 0;
                return this;
            }

            this.expiration_timestamp = (int) (new GLib.DateTime.now_utc ()).to_unix () + ttl;
            return this;
        }

        public CacheItemInterface expireAt (int timestamp) {
            this.expiration_timestamp = timestamp;
            this.keep_TTL = false;
            this.is_hit = true;
            return this;
        }

        public bool to_key_file (KeyFile key_file) {
            key_file.set_string (KEY_GROUP, "key", this.key);
            key_file.set_boolean (KEY_GROUP, "is_hit", this.is_hit);
            key_file.set_boolean (KEY_GROUP, "keep_ttl", this.keep_TTL);
            key_file.set_integer (KEY_GROUP, "ttl", this.ttl);
            key_file.set_integer (KEY_GROUP, "expiration_timestamp", this.expiration_timestamp);

            if (this.value == null) {
                key_file.set_boolean (KEY_GROUP, "has_value", false);
                return true;
            }

            key_file.set_boolean (KEY_GROUP, "has_value", true);

            Type value_type = this.value.type ();
            if (value_type == typeof (string)) {
                key_file.set_string (KEY_GROUP, "value_type", "string");
                key_file.set_string (KEY_GROUP, "value", this.value.get_string () ?? "");
                return true;
            }

            if (value_type == typeof (int)) {
                key_file.set_string (KEY_GROUP, "value_type", "int");
                key_file.set_integer (KEY_GROUP, "value", this.value.get_int ());
                return true;
            }

            if (value_type == typeof (int64)) {
                key_file.set_string (KEY_GROUP, "value_type", "int64");
                key_file.set_int64 (KEY_GROUP, "value", this.value.get_int64 ());
                return true;
            }

            if (value_type == typeof (uint)) {
                key_file.set_string (KEY_GROUP, "value_type", "uint");
                key_file.set_uint64 (KEY_GROUP, "value", this.value.get_uint ());
                return true;
            }

            if (value_type == typeof (uint64)) {
                key_file.set_string (KEY_GROUP, "value_type", "uint64");
                key_file.set_uint64 (KEY_GROUP, "value", this.value.get_uint64 ());
                return true;
            }

            if (value_type == typeof (bool)) {
                key_file.set_string (KEY_GROUP, "value_type", "bool");
                key_file.set_boolean (KEY_GROUP, "value", this.value.get_boolean ());
                return true;
            }

            if (value_type == typeof (double)) {
                key_file.set_string (KEY_GROUP, "value_type", "double");
                key_file.set_double (KEY_GROUP, "value", this.value.get_double ());
                return true;
            }

            if (value_type == typeof (Json.Node)) {
                Json.Node? root = (Json.Node?) this.value.get_boxed ();
                if (root == null) {
                    return false;
                }

                var generator = new Json.Generator ();
                generator.set_root (root);

                key_file.set_string (KEY_GROUP, "value_type", "json");
                key_file.set_string (KEY_GROUP, "value", generator.to_data (null));
                return true;
            }

            return false;
        }

        public static CacheItem? from_key_file (KeyFile key_file) {
            try {
                string key = key_file.get_string (KEY_GROUP, "key");
                var item = new CacheItem (key);
                item.is_hit = key_file.get_boolean (KEY_GROUP, "is_hit");
                item.keep_TTL = key_file.get_boolean (KEY_GROUP, "keep_ttl");
                item.ttl = key_file.get_integer (KEY_GROUP, "ttl");
                item.expiration_timestamp = key_file.get_integer (KEY_GROUP, "expiration_timestamp");

                if (!key_file.get_boolean (KEY_GROUP, "has_value")) {
                    item.value = null;
                    return item;
                }

                string value_type = key_file.get_string (KEY_GROUP, "value_type");

                if (value_type == "string") {
                    Value parsed = Value (typeof (string));
                    parsed.set_string (key_file.get_string (KEY_GROUP, "value"));
                    item.value = parsed;
                    return item;
                }

                if (value_type == "int") {
                    Value parsed = Value (typeof (int));
                    parsed.set_int (key_file.get_integer (KEY_GROUP, "value"));
                    item.value = parsed;
                    return item;
                }

                if (value_type == "int64") {
                    Value parsed = Value (typeof (int64));
                    parsed.set_int64 (key_file.get_int64 (KEY_GROUP, "value"));
                    item.value = parsed;
                    return item;
                }

                if (value_type == "uint") {
                    Value parsed = Value (typeof (uint));
                    parsed.set_uint ((uint) key_file.get_uint64 (KEY_GROUP, "value"));
                    item.value = parsed;
                    return item;
                }

                if (value_type == "uint64") {
                    Value parsed = Value (typeof (uint64));
                    parsed.set_uint64 (key_file.get_uint64 (KEY_GROUP, "value"));
                    item.value = parsed;
                    return item;
                }

                if (value_type == "bool") {
                    Value parsed = Value (typeof (bool));
                    parsed.set_boolean (key_file.get_boolean (KEY_GROUP, "value"));
                    item.value = parsed;
                    return item;
                }

                if (value_type == "double") {
                    Value parsed = Value (typeof (double));
                    parsed.set_double (key_file.get_double (KEY_GROUP, "value"));
                    item.value = parsed;
                    return item;
                }

                if (value_type == "json") {
                    var parser = new Json.Parser ();
                    parser.load_from_data (key_file.get_string (KEY_GROUP, "value"), -1);

                    Json.Node? root = parser.get_root ();
                    if (root == null) {
                        return null;
                    }

                    Value parsed = Value (typeof (Json.Node));
                    parsed.set_boxed (root.copy ());
                    item.value = parsed;
                    return item;
                }

                return null;
            } catch (Error e) {
                return null;
            }
        }
    }
}
