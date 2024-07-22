pub const Tokens = enum {
    __err, // panic (only in scanning)
    __esc, //escaped (only in scanning)

    // literals
    string,
    number,
    // metacharacters
    meta_dot, //.
    meta_caret, //^
    meta_dollar, //$
    meta_star, //*
    meta_plus, //+
    meta_comma, //,
    meta_line, //-
    meta_quest, //?
    meta_brac_open, //[
    meta_brac_close, //]
    meta_cur_open, //{
    meta_cur_close, //}
    meta_pipe, //|
    meta_prn_open, // (
    meta_prn_close, // )
    // escaped
    esc_digit, //\d
    esc_word, //\w
    esc_white, //\s
    esc_n_digit, //\D
    esc_n_word, //\W
    esc_n_white, //\S
    esc_tab, //\t
    esc_r, //\r
    esc_n, //\n
    esc_char, // any escaped special character (metacharacets) used in engine
};
