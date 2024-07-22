const std = @import("std");
const print = std.debug.print;
pub const Tokens = @import("tokens.zig").Tokens;

const Self = *Fsm;
const ALLOWED_LITERALS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#%&_/\"'`~ ;";
const SPECIA_CHARS_FOR_ESCAPE = ".^$*+,-?[]{}|()\\:";

pub const Unit = struct {
    token: Tokens,
    value: ?u8,
};

pub const Fsm = struct {
    allocator: std.mem.Allocator,
    data: []const u8,
    index: usize = 0,
    state: ?Tokens = null,
    col_num: usize = 0,
    result: std.ArrayList(Unit),

    pub fn init(allocator: std.mem.Allocator, data: []const u8) !Self {
        const res = std.ArrayList(Unit).init(allocator);
        const obj = Fsm{
            .allocator = allocator,
            .data = data,
            .result = res,
        };
        const ptr = try allocator.create(Fsm);
        ptr.* = obj;
        return ptr;
    }

    pub fn deinit(self: Self) void {
        self.result.deinit();
        self.allocator.destroy(self);
    }

    fn peek(self: Self) ?u8 {
        if (self.index > self.data.len - 1) {
            return null;
        }
        return self.data[self.index];
    }

    pub fn process(self: Self) void {
        self.next();
    }

    /// not allowed when peek is null
    fn advance(self: Self) void {
        if (self.peek()) |_| {
            self.col_num += 1;
            self.index += 1;
        } else {
            unreachable;
        }
    }

    fn append_unit(self: Self, c: ?u8) void {
        if (self.state == Tokens.__esc) {
            return;
        }
        self.result.append(Unit{
            .token = self.state.?,
            .value = c,
        }) catch |e| {
            @panic(@errorName(e));
        };
    }

    fn next(self: Self) void {
        if (self.state == null) {
            // default state
            if (self.peek() == null) {
                return;
            }
            const peeked = self.peek().?;
            if (is_allowed_literal(peeked)) {
                self.state = Tokens.string;
                self.next();
            } else if (is_number(peeked)) {
                self.state = Tokens.number;
                self.next();
            } else if (peeked == '.') {
                self.state = Tokens.meta_dot;
                self.next();
            } else if (peeked == '^') {
                self.state = Tokens.meta_caret;
                self.next();
            } else if (peeked == '$') {
                self.state = Tokens.meta_dollar;
                self.next();
            } else if (peeked == '*') {
                self.state = Tokens.meta_star;
                self.next();
            } else if (peeked == '+') {
                self.state = Tokens.meta_plus;
                self.next();
            } else if (peeked == ',') {
                self.state = Tokens.meta_comma;
                self.next();
            } else if (peeked == '-') {
                self.state = Tokens.meta_line;
                self.next();
            } else if (peeked == '?') {
                self.state = Tokens.meta_quest;
                self.next();
            } else if (peeked == '[') {
                self.state = Tokens.meta_brac_open;
                self.next();
            } else if (peeked == ']') {
                self.state = Tokens.meta_brac_close;
                self.next();
            } else if (peeked == '{') {
                self.state = Tokens.meta_cur_open;
                self.next();
            } else if (peeked == '}') {
                self.state = Tokens.meta_cur_close;
                self.next();
            } else if (peeked == '|') {
                self.state = Tokens.meta_pipe;
                self.next();
            } else if (peeked == '(') {
                self.state = Tokens.meta_prn_open;
                self.next();
            } else if (peeked == ')') {
                self.state = Tokens.meta_prn_close;
                self.next();
            } else if (peeked == ':') {
                self.state = Tokens.meta_collon;
                self.next();
            } else if (peeked == '\\') {
                self.state = Tokens.__esc;
                self.next();
            } else {
                self.state = Tokens.__err;
                self.next();
            }
        } else {
            if (self.peek() == null) {
                return;
            }
            switch (self.state.?) {
                Tokens.string => {
                    self.append_unit(self.peek());

                    self.advance();
                    self.state = null;
                    self.next();
                },
                Tokens.number => {
                    self.append_unit(self.peek());

                    self.advance();
                    self.state = null;
                    self.next();
                },
                Tokens.meta_dot,
                Tokens.meta_caret,
                Tokens.meta_dollar,
                Tokens.meta_star,
                Tokens.meta_plus,
                Tokens.meta_comma,
                Tokens.meta_line,
                Tokens.meta_quest,
                Tokens.meta_brac_open,
                Tokens.meta_brac_close,
                Tokens.meta_cur_open,
                Tokens.meta_cur_close,
                Tokens.meta_pipe,
                Tokens.meta_collon,
                Tokens.meta_prn_open,
                Tokens.meta_prn_close,
                => {
                    self.append_unit(self.peek());

                    self.advance();
                    self.state = null;
                    self.next();
                },
                Tokens.__esc => {
                    self.append_unit('\\');

                    self.advance();
                    if (self.peek()) |next_peek| {
                        if (next_peek == 'd') {
                            self.state = Tokens.esc_digit;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 'w') {
                            self.state = Tokens.esc_word;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 's') {
                            self.state = Tokens.esc_white;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 'D') {
                            self.state = Tokens.esc_n_digit;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 'W') {
                            self.state = Tokens.esc_n_word;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 'S') {
                            self.state = Tokens.esc_n_white;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 't') {
                            self.state = Tokens.esc_tab;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 'r') {
                            self.state = Tokens.esc_r;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else if (next_peek == 'n') {
                            self.state = Tokens.esc_n;
                            self.append_unit(next_peek);

                            self.advance();
                            self.state = null;
                            self.next();
                        } else {
                            var found = false;
                            for (SPECIA_CHARS_FOR_ESCAPE) |ec| {
                                if (ec == next_peek) {
                                    found = true;
                                    break;
                                }
                            }
                            if (!found) {
                                self.state = Tokens.__err;
                            } else {
                                self.state = Tokens.esc_char;
                                self.append_unit(next_peek);

                                self.advance();
                                self.state = null;
                            }
                            self.next();
                        }
                    } else {
                        self.state = Tokens.__err;
                        self.next();
                    }
                },
                Tokens.__err => {
                    // TODO panic
                    const stderr = std.io.getStdErr();
                    const message = std.fmt.allocPrint(self.allocator, "invalid token at col:{d}\n", .{self.col_num}) catch |e| {
                        @panic(@errorName(e));
                    };
                    stderr.writeAll(message) catch |e| {
                        @panic(@errorName(e));
                    };
                    std.process.exit(1);
                },
                else => unreachable,
            }
        }
    }

    fn is_allowed_literal(mc: ?u8) bool {
        if (mc == null) {
            return false;
        }
        var found = false;
        for (ALLOWED_LITERALS) |al| {
            if (al == mc) {
                found = true;
                break;
            }
        }
        return found;
    }

    fn is_number(mc: ?u8) bool {
        if (mc == null) {
            return false;
        }
        const c = mc.?;
        var found = false;
        for ('0'..'9') |t| {
            if (c == t) {
                found = true;
                break;
            }
        }
        return found;
    }
};
