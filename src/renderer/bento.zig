const std = @import("std");
const themes = @import("themes.zig");

/// Aspect ratio classification for a card slot in a grid.
pub const SlotAspect = enum {
    standard, // ~400-430px x ~160-200px (standard 50% width or equal card)
    tall_pillar, // ~400px x ~340-420px (vertical pillar spanning 2 stacked cards)
    wide_hero, // ~840-880px x ~140-220px (full-width horizontal banner)
    compact_col, // ~260-280px x ~160-200px (1 of 3 columns in a row)

    pub fn fromDimensions(w: f64, h: f64) SlotAspect {
        if (h <= 0) return .standard;
        const aspect_ratio = w / h;
        if (aspect_ratio >= 2.8) return .wide_hero;
        if (aspect_ratio <= 1.35) return .tall_pillar;
        if (w <= 300.0) return .compact_col;
        return .standard;
    }
};

/// A single geometric slot in the Bento Grid canvas.
pub const BentoSlot = struct {
    x: f64,
    y: f64,
    w: f64,
    h: f64,
    aspect: SlotAspect,
    card_id: []const u8,
};

/// Complete Bento Grid layout calculation output.
pub const BentoLayout = struct {
    canvas_w: f64,
    canvas_h: f64,
    slots: []BentoSlot,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *BentoLayout) void {
        self.allocator.free(self.slots);
    }
};

/// Height boundaries for the languages card to guarantee design integrity.
pub const HeightBounds = struct {
    min: u32,
    opt: u32,
    max: u32,
};

/// Calculates the exact [min, opt, max] height boundaries for L languages (6 to 16 languages).
/// Covered across 16 counts * 3 vertical states = 48 variations.
pub fn getLanguageHeightBounds(langs_count: usize) HeightBounds {
    const clamped_count = @min(@max(langs_count, 1), 25);
    const rows: u32 = @as(u32, @intCast((clamped_count + 1) / 2)); // ceil(langs / 2) for 2 columns

    // Minimum natural height matches svg.zig exactly:
    // bar_bottom (62) + standard_bar_to_row (34) + padding_y (28) + (rows - 1) * 34
    const min_h: u32 = 124 + (if (rows > 1) (rows - 1) * 34 else 0);
    // Optimal breathing room (row step ~41px)
    const opt_h: u32 = 134 + (if (rows > 1) (rows - 1) * 41 else 0);
    // Max expanded pillar (row step ~47px)
    const max_h: u32 = 146 + (if (rows > 1) (rows - 1) * 47 else 0);

    return HeightBounds{
        .min = min_h,
        .opt = opt_h,
        .max = max_h,
    };
}

/// Computes responsive Bento Grid layout coordinates for any combination of N cards (1 <= N <= 7).
pub fn computeBentoLayout(
    allocator: std.mem.Allocator,
    cards: []const []const u8,
    template_name: []const u8,
    target_w: f64,
    custom_gap: ?f64,
    custom_h: ?f64,
    langs_count: ?usize,
) !BentoLayout {
    const n = cards.len;
    if (n == 0) return error.EmptyCardList;

    // Enforce GitHub Profile bounds: between 360px and 896px max width
    const canvas_w = @min(@max(target_w, 360.0), 896.0);
    const gap = custom_gap orelse 12.0;

    const slots = try allocator.alloc(BentoSlot, n);
    errdefer allocator.free(slots);

    // Resolve template: auto-detect based on cards.len if empty or "auto"
    const is_auto = template_name.len == 0 or std.mem.eql(u8, template_name, "auto");
    const is_mobile = std.mem.eql(u8, template_name, "mobile") or std.mem.eql(u8, template_name, "mobile-stack");

    if (is_mobile) {
        // Mobile Linear Stack: Single vertical column
        const slot_w = canvas_w - (2.0 * gap);
        var cur_y = gap;

        for (cards, 0..) |card_id, i| {
            var slot_h: f64 = 180.0;
            if (std.mem.eql(u8, card_id, "languages") or std.mem.eql(u8, card_id, "lang")) {
                const count = langs_count orelse 8;
                slot_h = @floatFromInt(getLanguageHeightBounds(count).min);
            }
            slots[i] = BentoSlot{
                .x = gap,
                .y = cur_y,
                .w = slot_w,
                .h = slot_h,
                .aspect = SlotAspect.fromDimensions(slot_w, slot_h),
                .card_id = card_id,
            };
            cur_y += slot_h + gap;
        }

        return BentoLayout{
            .canvas_w = canvas_w,
            .canvas_h = cur_y,
            .slots = slots,
            .allocator = allocator,
        };
    }

    if (n == 1 or std.mem.eql(u8, template_name, "solo")) {
        // N = 1: Solo Card
        const slot_w = canvas_w - (2.0 * gap);
        const slot_h = custom_h orelse 200.0;
        slots[0] = BentoSlot{
            .x = gap,
            .y = gap,
            .w = slot_w,
            .h = slot_h,
            .aspect = SlotAspect.fromDimensions(slot_w, slot_h),
            .card_id = cards[0],
        };
        return BentoLayout{
            .canvas_w = canvas_w,
            .canvas_h = slot_h + (2.0 * gap),
            .slots = slots,
            .allocator = allocator,
        };
    }

    if (n == 2 or std.mem.eql(u8, template_name, "split-2x1") or (is_auto and n == 2)) {
        if (std.mem.eql(u8, template_name, "stack-1x2")) {
            // N = 2: Vertical Stack
            const slot_w = canvas_w - (2.0 * gap);
            const slot_h = if (custom_h) |h| (h - (3.0 * gap)) / 2.0 else 180.0;
            slots[0] = BentoSlot{
                .x = gap,
                .y = gap,
                .w = slot_w,
                .h = slot_h,
                .aspect = SlotAspect.fromDimensions(slot_w, slot_h),
                .card_id = cards[0],
            };
            slots[1] = BentoSlot{
                .x = gap,
                .y = gap + slot_h + gap,
                .w = slot_w,
                .h = slot_h,
                .aspect = SlotAspect.fromDimensions(slot_w, slot_h),
                .card_id = cards[1],
            };
            return BentoLayout{
                .canvas_w = canvas_w,
                .canvas_h = (2.0 * slot_h) + (3.0 * gap),
                .slots = slots,
                .allocator = allocator,
            };
        } else {
            // N = 2: Horizontal 50/50 Split
            const total_avail_w = canvas_w - (3.0 * gap);
            const slot_w = total_avail_w / 2.0;
            const slot_h = custom_h orelse 180.0;
            slots[0] = BentoSlot{
                .x = gap,
                .y = gap,
                .w = slot_w,
                .h = slot_h,
                .aspect = SlotAspect.fromDimensions(slot_w, slot_h),
                .card_id = cards[0],
            };
            slots[1] = BentoSlot{
                .x = gap + slot_w + gap,
                .y = gap,
                .w = slot_w,
                .h = slot_h,
                .aspect = SlotAspect.fromDimensions(slot_w, slot_h),
                .card_id = cards[1],
            };
            return BentoLayout{
                .canvas_w = canvas_w,
                .canvas_h = slot_h + (2.0 * gap),
                .slots = slots,
                .allocator = allocator,
            };
        }
    }

    if (n == 3 or (is_auto and n == 3)) {
        if (std.mem.eql(u8, template_name, "hero-top-split")) {
            // Top Hero (100%), Bottom 2 Split (50% / 50%)
            const total_avail_w = canvas_w - (3.0 * gap);
            const half_w = total_avail_w / 2.0;
            const full_w = canvas_w - (2.0 * gap);
            const row1_h = 180.0;
            const row2_h = 180.0;

            slots[0] = BentoSlot{ .x = gap, .y = gap, .w = full_w, .h = row1_h, .aspect = .wide_hero, .card_id = cards[0] };
            slots[1] = BentoSlot{ .x = gap, .y = gap + row1_h + gap, .w = half_w, .h = row2_h, .aspect = .standard, .card_id = cards[1] };
            slots[2] = BentoSlot{ .x = gap + half_w + gap, .y = gap + row1_h + gap, .w = half_w, .h = row2_h, .aspect = .standard, .card_id = cards[2] };

            return BentoLayout{
                .canvas_w = canvas_w,
                .canvas_h = row1_h + row2_h + (3.0 * gap),
                .slots = slots,
                .allocator = allocator,
            };
        } else if (std.mem.eql(u8, template_name, "pillar-left-stack")) {
            // Left Tall Pillar, Right 2 Stacked Cards
            const total_avail_w = canvas_w - (3.0 * gap);
            const col1_w = total_avail_w - (total_avail_w * 424.0) / 824.0;
            const col2_w = total_avail_w - col1_w;
            const card_h = 180.0;
            const pillar_h = (2.0 * card_h) + gap;

            slots[0] = BentoSlot{ .x = gap, .y = gap, .w = col1_w, .h = pillar_h, .aspect = .tall_pillar, .card_id = cards[0] };
            slots[1] = BentoSlot{ .x = gap + col1_w + gap, .y = gap, .w = col2_w, .h = card_h, .aspect = .standard, .card_id = cards[1] };
            slots[2] = BentoSlot{ .x = gap + col1_w + gap, .y = gap + card_h + gap, .w = col2_w, .h = card_h, .aspect = .standard, .card_id = cards[2] };

            return BentoLayout{
                .canvas_w = canvas_w,
                .canvas_h = pillar_h + (2.0 * gap),
                .slots = slots,
                .allocator = allocator,
            };
        } else {
            // Default / Flagship N = 3: Left 2 Stacked Cards, Right 1 Tall Pillar
            const total_avail_w = canvas_w - (3.0 * gap);
            const col1_w = (total_avail_w * 424.0) / 824.0; // Proportional 424px vs 400px
            const col2_w = total_avail_w - col1_w;
            const card_h = 180.0;
            const pillar_h = (2.0 * card_h) + gap; // Harmonized height

            slots[0] = BentoSlot{ .x = gap, .y = gap, .w = col1_w, .h = card_h, .aspect = .standard, .card_id = cards[0] };
            slots[1] = BentoSlot{ .x = gap, .y = gap + card_h + gap, .w = col1_w, .h = card_h, .aspect = .standard, .card_id = cards[1] };
            slots[2] = BentoSlot{ .x = gap + col1_w + gap, .y = gap, .w = col2_w, .h = pillar_h, .aspect = .tall_pillar, .card_id = cards[2] };

            return BentoLayout{
                .canvas_w = canvas_w,
                .canvas_h = pillar_h + (2.0 * gap),
                .slots = slots,
                .allocator = allocator,
            };
        }
    }

    if (n == 4 or (is_auto and n == 4)) {
        // Balanced 2x2 Matrix
        const total_avail_w = canvas_w - (3.0 * gap);
        const slot_w = total_avail_w / 2.0;
        const slot_h = 180.0;

        slots[0] = BentoSlot{ .x = gap, .y = gap, .w = slot_w, .h = slot_h, .aspect = .standard, .card_id = cards[0] };
        slots[1] = BentoSlot{ .x = gap + slot_w + gap, .y = gap, .w = slot_w, .h = slot_h, .aspect = .standard, .card_id = cards[1] };
        slots[2] = BentoSlot{ .x = gap, .y = gap + slot_h + gap, .w = slot_w, .h = slot_h, .aspect = .standard, .card_id = cards[2] };
        slots[3] = BentoSlot{ .x = gap + slot_w + gap, .y = gap + slot_h + gap, .w = slot_w, .h = slot_h, .aspect = .standard, .card_id = cards[3] };

        return BentoLayout{
            .canvas_w = canvas_w,
            .canvas_h = (2.0 * slot_h) + (3.0 * gap),
            .slots = slots,
            .allocator = allocator,
        };
    }

    if (n == 5 or (is_auto and n == 5)) {
        // N = 5: Top Hero (100% width, full 180px height) + 2x2 Core Matrix
        const full_w = canvas_w - (2.0 * gap);
        const total_avail_w = canvas_w - (3.0 * gap);
        const half_w = total_avail_w / 2.0;
        const hero_h = 180.0;
        const slot_h = 180.0;

        slots[0] = BentoSlot{ .x = gap, .y = gap, .w = full_w, .h = hero_h, .aspect = .wide_hero, .card_id = cards[0] };
        slots[1] = BentoSlot{ .x = gap, .y = gap + hero_h + gap, .w = half_w, .h = slot_h, .aspect = .standard, .card_id = cards[1] };
        slots[2] = BentoSlot{ .x = gap + half_w + gap, .y = gap + hero_h + gap, .w = half_w, .h = slot_h, .aspect = .standard, .card_id = cards[2] };
        slots[3] = BentoSlot{ .x = gap, .y = gap + hero_h + gap + slot_h + gap, .w = half_w, .h = slot_h, .aspect = .standard, .card_id = cards[3] };
        slots[4] = BentoSlot{ .x = gap + half_w + gap, .y = gap + hero_h + gap + slot_h + gap, .w = half_w, .h = slot_h, .aspect = .standard, .card_id = cards[4] };

        return BentoLayout{
            .canvas_w = canvas_w,
            .canvas_h = hero_h + (2.0 * slot_h) + (4.0 * gap),
            .slots = slots,
            .allocator = allocator,
        };
    }

    if (n == 6 or (is_auto and n == 6)) {
        // N = 6: 2 Columns x 3 Rows
        const total_avail_w = canvas_w - (3.0 * gap);
        const slot_w = total_avail_w / 2.0;
        const slot_h = 180.0;

        for (0..6) |i| {
            const col = i % 2;
            const row = i / 2;
            const cur_x = gap + @as(f64, @floatFromInt(col)) * (slot_w + gap);
            const cur_y = gap + @as(f64, @floatFromInt(row)) * (slot_h + gap);
            slots[i] = BentoSlot{ .x = cur_x, .y = cur_y, .w = slot_w, .h = slot_h, .aspect = .standard, .card_id = cards[i] };
        }

        return BentoLayout{
            .canvas_w = canvas_w,
            .canvas_h = (3.0 * slot_h) + (4.0 * gap),
            .slots = slots,
            .allocator = allocator,
        };
    }

    // Default N = 7 (The Complete Suite Master Dashboard)
    // Row 1: Top Hero Ribbon (100% width, height = 180.0px for full Milestones or any hero card)
    // Row 2, 3, 4: 2 Columns x 3 Rows (all slots width >= 414px, height = 180px)
    const full_w = canvas_w - (2.0 * gap);
    const hero_h = 180.0;
    const total_avail_w = canvas_w - (3.0 * gap);
    const slot_w = total_avail_w / 2.0;
    const slot_h = 180.0;

    // Row 1: Hero
    slots[0] = BentoSlot{ .x = gap, .y = gap, .w = full_w, .h = hero_h, .aspect = .wide_hero, .card_id = cards[0] };

    // Rows 2, 3, 4: 2 columns of 3 rows
    for (1..7) |i| {
        const pair_idx = i - 1;
        const col = pair_idx % 2;
        const row = pair_idx / 2;
        const cur_x = gap + @as(f64, @floatFromInt(col)) * (slot_w + gap);
        const cur_y = gap + hero_h + gap + @as(f64, @floatFromInt(row)) * (slot_h + gap);
        slots[i] = BentoSlot{ .x = cur_x, .y = cur_y, .w = slot_w, .h = slot_h, .aspect = .standard, .card_id = cards[i] };
    }

    return BentoLayout{
        .canvas_w = canvas_w,
        .canvas_h = gap + hero_h + gap + (3.0 * slot_h) + (3.0 * gap) + gap,
        .slots = slots,
        .allocator = allocator,
    };
}

/// Helper to prefix def IDs and CSS classes inside a sub-card SVG string
/// so that multiple cards embedded in one Bento SVG never have ID or CSS collisions.
pub fn namespaceSubCardSVG(
    allocator: std.mem.Allocator,
    raw_svg: []const u8,
    slot_idx: usize,
) ![]const u8 {
    var prefix_buf: [16]u8 = undefined;
    const prefix = try std.fmt.bufPrint(&prefix_buf, "b{d}_", .{slot_idx});

    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    // Scan for `id="` and replace with `id="b{i}_`
    // Scan for `url(#` and replace with `url(#b{i}_`
    // Scan for `href="#` and replace with `href="#b{i}_`
    var i: usize = 0;
    while (i < raw_svg.len) {
        if (std.mem.startsWith(u8, raw_svg[i..], "id=\"")) {
            try w.writeAll("id=\"");
            try w.writeAll(prefix);
            i += 4;
        } else if (std.mem.startsWith(u8, raw_svg[i..], "url(#")) {
            try w.writeAll("url(#");
            try w.writeAll(prefix);
            i += 5;
        } else if (std.mem.startsWith(u8, raw_svg[i..], "href=\"#")) {
            try w.writeAll("href=\"#");
            try w.writeAll(prefix);
            i += 7;
        } else {
            try w.writeByte(raw_svg[i]);
            i += 1;
        }
    }

    return try stream.toOwnedSlice();
}

/// Strips the outer `<svg ...>` opening tag and closing `</svg>` from a sub-card SVG string,
/// returning the inner contents ready to be wrapped in a nested `<svg x y w h>` element.
pub fn extractSvgInner(raw_svg: []const u8) []const u8 {
    const start_tag_end = std.mem.indexOfScalar(u8, raw_svg, '>') orelse return raw_svg;
    const inner_start = start_tag_end + 1;

    const end_tag_start = std.mem.lastIndexOf(u8, raw_svg, "</svg>") orelse raw_svg.len;
    if (end_tag_start > inner_start) {
        return std.mem.trim(u8, raw_svg[inner_start..end_tag_start], " \t\r\n");
    }
    return raw_svg;
}

/// Composes the unified master Bento Grid SVG banner.
pub fn composeBentoSVG(
    allocator: std.mem.Allocator,
    layout: *const BentoLayout,
    rendered_cards: []const []const u8,
    theme: themes.Theme,
    border_radius: f64,
    hide_border: bool,
) ![]const u8 {
    if (rendered_cards.len != layout.slots.len) return error.MismatchedCardCount;

    var stream = std.Io.Writer.Allocating.init(allocator);
    defer stream.deinit();
    const w = &stream.writer;

    // Master SVG Opening
    try w.print(
        \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d:.1} {d:.1}" width="{d:.1}" height="{d:.1}">
        \\  <defs>
        \\    <linearGradient id="bento-bg-grad" x1="0%" y1="0%" x2="100%" y2="100%">
        \\      <stop offset="0%" stop-color="{s}" stop-opacity="1.0"/>
        \\      <stop offset="100%" stop-color="{s}" stop-opacity="0.95"/>
        \\    </linearGradient>
        \\  </defs>
        \\  <style>
        \\    .bento-master {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }}
        \\    .bento-slot {{ overflow: hidden; }}
        \\  </style>
        \\
    , .{
        layout.canvas_w,
        layout.canvas_h,
        layout.canvas_w,
        layout.canvas_h,
        theme.bg_color,
        theme.bg_color,
    });

    // Master Outer Background
    const stroke_attr = if (hide_border)
        "stroke=\"none\""
    else
        "stroke=\"#24283b\" stroke-width=\"1\"";

    try w.print(
        \\  <!-- Master Bento Canvas Frame -->
        \\  <rect width="{d:.1}" height="{d:.1}" rx="{d:.1}" fill="url(#bento-bg-grad)" {s}/>
        \\
    , .{ layout.canvas_w, layout.canvas_h, border_radius, stroke_attr });

    // Render each slot with nested <svg> encapsulation and isolated ID namespacing
    for (layout.slots, 0..) |slot, idx| {
        const raw_card_svg = rendered_cards[idx];
        const namespaced_svg = try namespaceSubCardSVG(allocator, raw_card_svg, idx);
        defer allocator.free(namespaced_svg);

        const inner_content = extractSvgInner(namespaced_svg);

        try w.print(
            \\  <!-- Slot {d}: {s} ({s}) -->
            \\  <svg x="{d:.1}" y="{d:.1}" width="{d:.1}" height="{d:.1}" viewBox="0 0 {d:.1} {d:.1}" class="bento-slot bento-slot-{d}">
            \\    {s}
            \\  </svg>
            \\
        , .{
            idx + 1,
            slot.card_id,
            @tagName(slot.aspect),
            slot.x,
            slot.y,
            slot.w,
            slot.h,
            slot.w,
            slot.h,
            idx + 1,
            inner_content,
        });
    }

    try w.writeAll("</svg>");
    return try stream.toOwnedSlice();
}
