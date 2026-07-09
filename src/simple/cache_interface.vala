namespace ValaFoundation.CacheManager.Simple {
    using Gee;
    using GLib;

    public interface CacheInterface : Object {
        public abstract Value? getValue (string key, Value? default_value = null);
        public abstract bool setValue (string key, Value value, int ttl = 0);
        public abstract bool deleteValue (string key);
        public abstract bool clear ();
        public abstract bool has (string key);

        public abstract Gee.Map<string, Value?> getMultiple (string[] keys, Value? default_value = null);
        public abstract bool setMultiple (Gee.Map<string, Value?> items, int ttl = 0);
        public abstract bool deleteMultiple (string[] keys);
    }
}
