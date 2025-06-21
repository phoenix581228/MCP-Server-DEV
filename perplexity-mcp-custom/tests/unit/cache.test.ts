import { describe, it, expect, beforeEach, vi } from 'vitest';
import { LRUCache } from '../../src/utils/cache';

describe('LRUCache', () => {
  let cache: LRUCache<string, string>;

  beforeEach(() => {
    // 5 items max, 1 second TTL for testing
    cache = new LRUCache({ max: 5, ttl: 1000 });
  });

  it('should store and retrieve values', () => {
    cache.set('key1', 'value1');
    expect(cache.get('key1')).toBe('value1');
  });

  it('should return undefined for non-existent keys', () => {
    expect(cache.get('nonexistent')).toBeUndefined();
  });

  it('should evict oldest item when capacity is reached', () => {
    // Fill cache
    for (let i = 1; i <= 5; i++) {
      cache.set(`key${i}`, `value${i}`);
    }

    // Add one more - should evict key1
    cache.set('key6', 'value6');

    expect(cache.get('key1')).toBeUndefined();
    expect(cache.get('key6')).toBe('value6');
    expect(cache.size()).toBe(5);
  });

  it('should update LRU order on get', () => {
    // Fill cache
    for (let i = 1; i <= 5; i++) {
      cache.set(`key${i}`, `value${i}`);
    }

    // Access key1 - moves it to end
    cache.get('key1');

    // Add new item - should evict key2, not key1
    cache.set('key6', 'value6');

    expect(cache.get('key1')).toBe('value1');
    expect(cache.get('key2')).toBeUndefined();
  });

  it('should expire items based on TTL', async () => {
    cache.set('key1', 'value1');
    
    // Value should exist immediately
    expect(cache.get('key1')).toBe('value1');

    // Wait for TTL to expire
    await new Promise(resolve => setTimeout(resolve, 1100));

    // Value should be expired
    expect(cache.get('key1')).toBeUndefined();
  });

  it('should clear all items', () => {
    cache.set('key1', 'value1');
    cache.set('key2', 'value2');

    cache.clear();

    expect(cache.get('key1')).toBeUndefined();
    expect(cache.get('key2')).toBeUndefined();
    expect(cache.size()).toBe(0);
  });

  it('should update existing keys without affecting size', () => {
    cache.set('key1', 'value1');
    expect(cache.size()).toBe(1);

    cache.set('key1', 'updatedValue');
    expect(cache.get('key1')).toBe('updatedValue');
    expect(cache.size()).toBe(1);
  });
});