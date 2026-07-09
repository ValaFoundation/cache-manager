namespace ValaFoundation.CacheManager.Memory {
    using ValaFoundation.CacheManager;

    public class CacheItem : Object, CacheItemInterface {

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

            // ttl <= 0 means "no expiration".
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
    }
}
