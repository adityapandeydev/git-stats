const std = @import("std");

/// LanguageStat represents a single language's statistics.
pub const LanguageStat = struct {
    name: []const u8,
    color: []const u8,
    size: u64,
    percentage: f64,
};

/// UserStats represents aggregated language stats for a GitHub user.
pub const UserStats = struct {
    username: []const u8,
    total_bytes: u64,
    languages: []LanguageStat,
};
