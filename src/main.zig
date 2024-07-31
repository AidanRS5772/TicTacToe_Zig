const std = @import("std");

pub fn Board(comptime N: usize) type {
    return struct {
        const This = @This();
        board: std.PackedIntArray(i2, N * N),

        pub fn init() This {
            return This{ .board = std.PackedIntArray(i2, N * N).initAllTo(0) };
        }

        pub fn move(this: *This, player: i2, row: usize, col: usize) !void {
            if ((row < N) or (col < N)) return error.IndexOutOfBounds;
            if (this.board.get(N * row + col) != 0) return error.IndexIsFull;
            this.board.set(N * row + col, player);
        }

        pub fn isometries(this: This) [8]This {
            var isom: [8]This = undefined;
            const id: This = this;
            isom[0] = id;

            const r1 = struct {
                fn f(row: usize, col: usize) usize {
                    return N * (N - col) + row;
                }
            }.f;
            const r2 = struct {
                fn f(row: usize, col: usize) usize {
                    return N * (N - col) + (N - row);
                }
            }.f;
            const r3 = struct {
                fn f(row: usize, col: usize) usize {
                    return N * (N - row) + (N - col);
                }
            }.f;
            const td1 = struct {
                fn f(row: usize, col: usize) usize {
                    return N * col + row;
                }
            }.f;
            const td2 = struct {
                fn f(row: usize, col: usize) usize {
                    return N * (N - col) + (N - row);
                }
            }.f;
            const tx = struct {
                fn f(row: usize, col: usize) usize {
                    return N * row + (N - col);
                }
            }.f;
            const ty = struct {
                fn f(row: usize, col: usize) usize {
                    return N * (N - row) + col;
                }
            }.f;

            const transforms = &[7]fn (row: usize, col: usize) usize{ r1, r2, r3, td1, td2, tx, ty };

            for (transforms, 0..) |transform, i| {
                var board = std.PackedIntArray(i2, N * N).initAllTo(0);
                for (0..N) |row| {
                    for (0..N) |col| {
                        board.set(N * row + col, this.board.get(transform(row, col)));
                    }
                }
                isom[i + 1] = This{ .board = board };
            }

            return isom;
        }

        pub fn is_win(this: This) i2 {
            //check rows
            for (0..N) |row| {
                const start = this.board.get(N * row);
                if (start != 0) {
                    var win_state = true;
                    for (1..N) |col| {
                        const crnt = this.board.get(N * row + col);
                        if (crnt == 0) {
                            win_state = false;
                            break;
                        }
                        if (start != crnt) {
                            win_state = false;
                            break;
                        }
                    }

                    if (win_state) {
                        return start;
                    }
                }
            }

            // check cols
            for (0..N) |col| {
                const start = this.board.get(col);
                if (start != 0) {
                    var win_state = true;
                    for (1..N) |row| {
                        const crnt = this.board.get(N * row + col);
                        if (crnt == 0) {
                            win_state = false;
                            break;
                        }
                        if (start != crnt) {
                            win_state = false;
                            break;
                        }
                    }

                    if (win_state) {
                        return start;
                    }
                }
            }

            //check primary diagonal
            const start1 = this.board.get(0);
            if (start1 != 0) {
                var win_state = true;
                for (1..N) |i| {
                    const crnt = this.board.get((N + 1) * i);
                    if (crnt == 0) {
                        win_state = false;
                        break;
                    }
                    if (start1 != crnt) {
                        win_state = false;
                        break;
                    }
                }

                if (win_state) {
                    return start1;
                }
            }

            //check secondary diagonal
            const start2 = this.board.get(N - 1);
            if (start2 != 0) {
                var win_state = true;
                for (1..N) |i| {
                    const crnt = this.board.get((N - 1) * i);
                    if (crnt == 0) {
                        win_state = false;
                        break;
                    }
                    if (start2 != crnt) {
                        win_state = false;
                        break;
                    }
                }

                if (win_state) {
                    return start2;
                }
            }
        }

        pub fn print_board(this: This) void {
            std.debug.print("\n", .{});
            for (0..N) |row| {
                for (0..N) |col| {
                    const val = this.board.get(N * row + col);
                    if (val == 0) {
                        std.debug.print("#", .{});
                    } else if (val == 1) {
                        std.debug.print("O", .{});
                    } else {
                        std.debug.print("X", .{});
                    }
                }
            }
            std.debug.print("\n", .{});
        }
    };
}

pub fn Queue(comptime T: type) type {
    return struct {
        const This = @This();
        const QNode = struct {
            data: T,
            next: ?*QNode,
        };
        a: std.mem.Allocator,
        start: ?*QNode,
        end: ?*QNode,
        len: usize,

        pub fn init(a: std.mem.Allocator) This {
            return This{ .a = a, .start = null, .end = null, .len = 0 };
        }
        pub fn in(this: *This, value: T) !void {
            const node = try this.a.create(QNode);
            node.* = .{ .data = value, .next = null };
            if (this.end) |end| end.next = node //
            else this.start = node;
            this.end = node;
            this.len += 1;
        }
        pub fn out(this: *This) !T {
            const start = this.start orelse return error.QueueIsEmpty;
            defer this.a.destroy(start);
            if (start.next) |next|
                this.start = next
            else {
                this.start = null;
                this.end = null;
            }
            this.len -= 1;
            return start.data;
        }
        pub fn deinit(this: *This) void {
            var crnt: ?T = this.out();
            while (crnt != null) {
                crnt = this.out();
            }
        }
    };
}

pub fn Tree(comptime N: usize) type {
    return struct {
        const This = @This();
        const TNode = struct {
            parents: std.ArrayList(*TNode),
            children: [N * N]?*TNode,
            val: Board(N),

            pub fn init(a: std.mem.Allocator, board: Board(N)) !*TNode {
                const out: *TNode = try a.create(TNode);
                out = .{ .parents = std.ArrayList(*TNode).init(a), .children = [N * N]?*TNode{null} ** (N * N), .val = board };
                return out;
            }

            pub fn deinit(self: *TNode, a: std.mem.Allocator) void {
                // Deinitialize children
                for (self.children) |maybe_child| {
                    if (maybe_child) |child| {
                        for (0..child.parents.items.len) |i| {
                            if (child.parents.items[i] == self) {
                                _ = child.parents.swapRemove(i);
                                break;
                            }
                        }
                        if (child.parents.items.len == 0) {
                            child.deinit(a);
                        }
                    }
                }

                self.parents.deinit();
                a.destroy(self);
            }
        };

        a: std.mem.Allocator,
        root: *TNode,
        lvl: usize,
        player: i2,

        pub fn init(a: std.mem.Allocator) This {
            return This{ .a = a, .root = TNode.init(a, Board(N).init()), .lvl = 0, .player = 1 };
        }

        fn add_terminals_to_queue(node: ?*TNode, q: *Queue(*TNode)) !void {
            if (node == null) return;

            var state = true;
            for (0..7) |i| {
                if (node.?.children[i] != null) {
                    state = false;
                    break;
                }
            }
            if (state) {
                try q.in(node.?);
            }

            for (node.?.children) |child| {
                try add_terminals_to_queue(child, q);
            }
        }

        pub fn propogate(this: *This, timer: i64) !void {
            var q = Queue(*TNode).init(this.a);
            errdefer q.deinit();
            try add_terminals_to_queue(this.root, &q);
            var h = std.AutoHashMap(Board(N), *TNode).init(this.a);
            errdefer h.deinit();

            const start_time = std.time.milliTimestamp();
            var lvl_time = std.time.milliTimestamp();
            var lvl_times = std.ArrayList(i64).init(this.a);
            errdefer lvl_times.deinit();

            var qlen: usize = q.len;

            std.debug.print("Level || Node Count\n", .{});
            std.debug.print("-------------------\n", .{});
            while (true) {
                if (qlen == 0) {
                    this.lvl += 1;
                    this.player *= -1;
                    qlen = q.len;
                    h.clearRetainingCapacity();
                    try lvl_times.append(std.time.milliTimestamp() - lvl_time);
                    lvl_time = std.time.milliTimestamp();
                    if (this.lvl < 10) {
                        std.debug.print("{}     || {}\n", .{ this.lvl, qlen });
                    } else {
                        std.debug.print("{}    || {}\n", .{ this.lvl, qlen });
                    }
                    if (std.time.milliTimestamp() - start_time > timer) break;
                }

                var crnt = try q.out();
                qlen -= 1;

                for (0..N) |row| {
                    for (0..N) |col| {
                        var new_board:Board(N) = crnt.val;
                        try new_board.move(this.player, row, col) catch {
                            continue;
                        };
                        const isoms:[8]Board(N) = new_board.isometries();
                        var not_in_tree = true;
                        for (isoms) |isom|{
                            if (h.get(isom)) |node|{
                                try node.parents.append(crnt);
                                crnt.children[N*row+col] = node;
                                not_in_tree = false;
                                break;
                            }
                        }
                        if (not_in_tree){
                            const child = try TNode.init(this.a, new_board);
                            try child.parents.append(crnt);
                            crnt.children[N*row+col] = child;
                            try h.put(new_board, child);
                            if (new_board.is_win() != 0){
                                try q.in(child);
                            }
                        }
                    }
                }
            }

            std.debug.print("\n\n", .{});
            std.debug.print("Level || Times (ms)\n", .{});
            std.debug.print("-------------------\n", .{});
            for (lvl_times.items, 0..) |time, i|{
                if (i < 10){
                    std.debug.print("{}     || {}\n", .{ i+1, time });
                }else{
                    std.debug.print("{}    || {}\n", .{ i+1, time });
                }
            }
        }

        pub fn deinit(this: *This) !void{
            this.root.deinit(this.a);
            this.lvl = 0;
            this.player = 1;
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    errdefer std.debug.assert(gpa.deinit() == .ok);

    var tree = Tree(3).init(a);
    errdefer tree.deinit();
    try tree.propogate(10000);
}
