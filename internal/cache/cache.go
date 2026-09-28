package cache

import (
	"sync"
	"time"
)

type item[T any] struct {
	value      T
	expiration time.Time
}

func (i item[T]) isExpired() bool {
	return time.Now().After(i.expiration)
}

// MemoryCache is a generic, thread-safe in-memory cache with TTL.
type MemoryCache[T any] struct {
	mu    sync.RWMutex
	items map[string]item[T]
	ttl   time.Duration
}

// New creates a new MemoryCache with the specified default TTL and cleanup interval.
func New[T any](defaultTTL time.Duration, cleanupInterval time.Duration) *MemoryCache[T] {
	c := &MemoryCache[T]{
		items: make(map[string]item[T]),
		ttl:   defaultTTL,
	}

	if cleanupInterval > 0 {
		go c.startCleanup(cleanupInterval)
	}

	return c
}

// Get retrieves an item from the cache if it exists and has not expired.
func (c *MemoryCache[T]) Get(key string) (T, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	it, found := c.items[key]
	if !found {
		var zero T
		return zero, false
	}

	if it.isExpired() {
		var zero T
		return zero, false
	}

	return it.value, true
}

// Set adds or replaces an item in the cache with the default TTL.
func (c *MemoryCache[T]) Set(key string, value T) {
	c.SetWithTTL(key, value, c.ttl)
}

// SetWithTTL adds or replaces an item in the cache with a custom TTL.
func (c *MemoryCache[T]) SetWithTTL(key string, value T, ttl time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.items[key] = item[T]{
		value:      value,
		expiration: time.Now().Add(ttl),
	}
}

// Delete removes an item from the cache.
func (c *MemoryCache[T]) Delete(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()

	delete(c.items, key)
}

// Clear flushes all items in the cache.
func (c *MemoryCache[T]) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.items = make(map[string]item[T])
}

func (c *MemoryCache[T]) startCleanup(interval time.Duration) {
	ticker := time.NewTicker(interval)
	for range ticker.C {
		c.mu.Lock()
		now := time.Now()
		for k, v := range c.items {
			if now.After(v.expiration) {
				delete(c.items, k)
			}
		}
		c.mu.Unlock()
	}
}
