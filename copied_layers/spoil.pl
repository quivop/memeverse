

layerinfo "type" = "layout";
layerinfo "name" = "Spoil Those Comments";
layerinfo "is_public" = 1;
layerinfo "source_viewable" = 1;
layerinfo "majorversion" = 0;
layerinfo "minorversion" = 7;

###############################################################################################
# PROPERTIES FOR SPOILERS
###############################################################################################

property bool spoiler_black_on_black {
    des = "Convert blacked-out spoilers to spoiler cuts?";
    note = """
        This makes a spoiler cut for each tag of the form
        <span class="background: black; color: black;">,
        as well as several variants.
    """;
}

property bool spoiler_white_text {
    des = "Convert white text spoilers to spoiler cuts?";
    note = """
        This makes a spoiler cut for each tag of the form
        <font color="white">,
        as well as several variants.
    """;
}

property bool spoiler_special_tag_use {
    des = "Convert a special tag to spoiler cuts?";
    note = """
        This makes a spoiler cut for a special, user-defined attribute, e.g.
        tags of the form <div cut>, <span cut>, or <font cut>.  Note that DW's
        tag-processing in comments means that this probably won't work for common
        HTML attributes, but "spoiler" or "cut" should work fine here.
    """;
}

property string spoiler_special_tag_name {
    des = "The name of the special attribute to use for cutting:";
    note = """
        For example, if this is set to the default value of "cut", then all
        tags of the form <div cut> or <span cut> or <font cut> will cause the
        creation of a spoiler cut.  Useful for when you want users to be able
        to mark things as belonging under a spoiler cut, but not show up blacked
        out or whited out in any layouts not based on this one.
    """;
}

property string spoiler_cut_text_closed {
    des = "Text used when the spoiler cut is closed:";
}

property string spoiler_cut_text_open {
    des = "Text used when the spoiler cut is open:";
}

property bool spoiler_cut_entries {
    des = "Convert spoiler cuts in entries?";
    note = """
        Although DW has built-in support for cut tags, enabling spoiler tags
        in entries may be useful in demonstrating the use of cut tags.
    """;
}

property bool spoiler_cut_show_open {
    des = "Show the link to close the spoiler?";
}

property bool spoiler_show_checkboxes {
    des = "Show checkboxes?";
    note = """
        This shows the checkboxes that are used to control the spoiler cuts,
        and should be enabled for debugging purposes only.
    """;
}

property string spoiler_fix_colors_text {
    des = "The text used for link to fix colors:";
}

property string spoiler_reset_colors_text {
    des = "The text used for link to reset colors:";
}

property Color spoiler_fallback_color {
    des = "The background/foreground color used as the fallback for older browsers.";
}   

property bool spoiler_hard_links {
    des = "Use hard links to show spoilers?";
    note = """
        Instead of using black-on-black spoilers as a fallback for older browsers,
        generate hard links for opening spoiler cuts.
    """;
}

property bool spoiler_hard_open_all {
    des = "Hard links open all spoilers in comment?";
    note = """
        Check this if you want clicking on a spoiler hard link to open all spoiler
        cuts in the comment.  Otherwise, the cuts will be opened one at a time.
    """;
}

property bool spoiler_fix_colors_comment {
    des = "Hidden property for checking whether color fixing links are enabled.";
    noui = 1;
}

property bool spoiler_are_cuts_enabled {
    des = "Hidden property for checking whether spoiler cuts are enabled.";
    noui = 1;
}

###############################################################################################
# DEFAULT VALUES FOR SPOILERS
###############################################################################################

set spoiler_cut_text_closed = "Spoilers (click to open)";
set spoiler_cut_text_open = "Spoilers (click to close)";
set spoiler_cut_show_open = true;

set spoiler_black_on_black = true;
set spoiler_white_text = true;

set spoiler_special_tag_use = false;
set spoiler_special_tag_name = "cut";

set spoiler_cut_entries = false;
set spoiler_show_checkboxes = false;

set spoiler_fix_colors_text = "Override Spoiler Colors";
set spoiler_reset_colors_text = "Reset Spoiler Colors";

set spoiler_hard_links = false;
set spoiler_hard_open_all = false;

###############################################################################################
# UTILITY FUNCTIONS
###############################################################################################

# strip whitespace from the ends of a string
function strip(string s) : string {
    while ($s->starts_with(" ")) {
        $s = $s->substr(1, $s->length() - 1);
    }

    while ($s->ends_with(" ")) {
        $s = $s->substr(0, $s->length() - 1);
    }

    return $s;
}

# separates the given string into tags and otherwise
function extract_tags(string input) : string[] {
    # simpler than it might be, because DW prettifies the HTML before it gets here

    var string[] result;
    var int count = 0;

    var string[] pieces = $input->split("<");
    foreach var string piece ($pieces) {
        if ($count == 0) {
            $result[$count++] = $piece;
            continue;
        }

        var string[] subpieces = $piece->split(">");

        $result[$count++] = "<" + $subpieces[0] + ">";
        if (size $subpieces > 1) {
            $result[$count++] = $subpieces[1];
        }
    }

    return $result;
}

function chop(string[] inputs, string divide, bool keep) : string[] {
    var string[] result;
    var int count = 0;

    foreach var string input ($inputs) {
        var string[] pieces = $input->split($divide);
        var bool first = true;
        foreach var string piece ($pieces) {
            if ($first) {
                $first = false;
            } elseif ($keep) {
                $result[$count++] = $divide;
            }

            if ($piece != "") {
                $result[$count++] = $piece;
            }
        }

        if ($keep and $input->ends_with($divide)) {
            $result[$count++] = $divide;
        }
    }

    return $result;
}

# tokenize a tag
function tokenize(string tag) : string[] {
    # simpler than it might be, because DW prettifies the HTML before it gets here

    var string[] result;
    var int count = 0;

    var string[] quotePieces = $tag->split("\"");

    for (var int i = 0; $i < size($quotePieces); $i = $i + 2) {
        var string[] tokens = [$quotePieces[$i]];
        $tokens = chop($tokens, "=", true);
        $tokens = chop($tokens, "/", true);
        $tokens = chop($tokens, "<", true);
        $tokens = chop($tokens, ">", true);
        $tokens = chop($tokens, " ", false);
        $tokens = chop($tokens, "\n", false);
        $tokens = chop($tokens, "\t", false);

        foreach var string token ($tokens) {
            $result[$count++] = $token->lower();
        }

        if ($i + 1 < size($quotePieces)) {
            $result[$count++] = $quotePieces[$i + 1];
        }
    }

    return $result;
}

###############################################################################################
# CODE FOR ADDING SPOILER CUTS
###############################################################################################

# create the beginning of a spoiler tag
# adjusts based on the values of certain properties
function get_open_spoiler_original(string identifier, string title, string link) : string {
    var string result = "";

    $result = $result + """<a name="$identifier-anchor"></a>""";

    $result = $result + """<input type="checkbox" id="$identifier" class="spoiler">""";
    $result = $result + """<span class="spoilerCut">""";
    $result = $result + """<span class="spoilerLink">""";

    $result = $result + """[""";
    $result = $result + """<a href="$link#$identifier-anchor">""";

    # fallback for older browsers
    $result = $result + """<span class="fallback">""";
    if ($title == "") {
        $result = $result + $*spoiler_cut_text_closed;
    } else {
        $result = $result + $title;
    }    
    $result = $result + """</span>""";

    $result = $result + """<label for="$identifier">""";

    if ($title == "") {
        if ($*spoiler_cut_show_open) {
            $result = $result + """<span class="open">""";
            $result = $result + "$*spoiler_cut_text_closed";
            $result = $result + """</span>""";
            $result = $result + """<span class="close">""";
            $result = $result + "$*spoiler_cut_text_open";
            $result = $result + """</span>""";
        } else {
            $result = $result + "$*spoiler_cut_text_closed";
        }
    } else {
        $result = $result + "$title";
    }

    $result = $result + """</label>""";
    $result = $result + """</a>""";
    $result = $result + """]""";
    $result = $result + """</span>""";
    $result = $result + """<span class="spoilerHidden">""";

    if ($*spoiler_cut_show_open) {
        $result = $result + "\n";
    }

    return $result;
}

function get_open_spoiler_exception(string identifier, string title, string link) : string {
    var string result = "";

    $result = $result + """<a name="$identifier-anchor"></a>""";
    $result = $result + """<span class="spoilerShow">""";

    if ($*spoiler_cut_show_open) {
        $result = $result + """<span class="spoilerLink">""";
        $result = $result + """[""";
        $result = $result + """<a href="$link#$identifier-anchor">""";

        if ($title == "") {
            $result = $result + "$*spoiler_cut_text_open";
        } else {
            $result = $result + "$title";
        }

        $result = $result + """</a>""";
        $result = $result + """]""";
        $result = $result + """</span>""";
    }

    $result = $result + """<span class="spoilerVisible">""";

    if ($*spoiler_cut_show_open) {
        $result = $result + "\n";
    }

    return $result;
}

function get_open_spoiler_fallback(string identifier, string title, string spoilerType) : string {
    var string result = "";

    $result = $result + """<input type="checkbox" id="$identifier" class="spoiler" checked>""";
    $result = $result + """<span class="spoilerCut$spoilerType">""";
    $result = $result + """<a name="$identifier-anchor"></a>""";
    $result = $result + """<span class="spoilerLink">""";

    $result = $result + """[""";
    $result = $result + """<span class="wrapper">""";
    $result = $result + """<a href="#$identifier-anchor">""";
    $result = $result + """<label for="$identifier">""";

    if ($title == "") {
        if ($*spoiler_cut_show_open) {
            $result = $result + """<span class="open">""";
            $result = $result + "$*spoiler_cut_text_closed";
            $result = $result + """</span>""";
            $result = $result + """<span class="close">""";
            $result = $result + "$*spoiler_cut_text_open";
            $result = $result + """</span>""";
        } else {
            $result = $result + "$*spoiler_cut_text_closed";
        }
    } else {
        $result = $result + "$title";
    }

    $result = $result + """</label>""";
    $result = $result + """</a>""";
    $result = $result + """</span>""";
    $result = $result + """]""";
    $result = $result + """</span>""";
    $result = $result + """<span class="spoilerHidden">""";

    if ($*spoiler_cut_show_open) {
        $result = $result + "\n";
    }

    return $result;
}

function get_open_spoiler(string identifier, string cut, string title, string permalink, string spoilerType) : string {
    if ($*spoiler_hard_links) {
        var Page p = get_page();
        var string exception = $p.args{"exception"};

        var string newCuts = "";
        var bool isException = false;
        if ($exception == $identifier) {
            if ($*spoiler_hard_open_all) {
                $isException = true;
            } else {
                var string[] openCuts = $p.args{"cuts"}->split(":");
                foreach var string openCut ($openCuts) {
                    if ("$cut" == "$openCut") {
                        $isException = true;
                    } else {
                        $newCuts = "$newCuts:$openCut";
                    }
                }

                if (not $isException) {
                    $newCuts = "$newCuts:$cut";
                }

                $newCuts = $newCuts->substr(1, $newCuts->length() - 1);
            }
        } else {
            if (not $*spoiler_hard_open_all) {
                $newCuts = $cut;
            }
        }

        var string additional = "";
        if ($*spoiler_hard_open_all) {
            if (not $isException) {
                $additional = ".exception=$identifier";
            }
        } else {
            if ($newCuts != "") {
                $additional = ".exception=$identifier";
                $additional = "$additional&.cuts=$newCuts";
            }
        }

        var string toggleLink = $permalink;
        if ($toggleLink->contains("?")) {
            $toggleLink = "$toggleLink&$additional";
        } else {
            $toggleLink = "$toggleLink?$additional";
        }
        
        if ($isException) {
            return get_open_spoiler_exception("$identifier-$cut", $title, $toggleLink);
        } else {
            return get_open_spoiler_original("$identifier-$cut", $title, $toggleLink);
        }
    } else {
        return get_open_spoiler_fallback("$identifier-$cut", $title, $spoilerType);
    }
}

# closes the spoiler tag
function get_close_spoiler() : string {
    return "</span></span>";
}

function add_cut_tags(string text, string unique, string permalink) : string {
    var string[] pieces = extract_tags($text);
    var string ret = "";
    var int index = 0;

    var bool[] stack;
    var int stackLength = 0;

    foreach var string piece ($pieces) {
        if ($piece->starts_with("<")) {
            var string[] tokens = tokenize($piece);

            var string type = $tokens[1];
            var bool isClosing = false;
            if ($type == "/") {
                $isClosing = true;
                $type = $tokens[2];
            }

            var bool selfClosing = false;
            if ($tokens[-2] == "/") {
                $selfClosing = true;
            }

            if ($selfClosing) {
                $ret = $ret + $piece;
            } elseif ($type == "div" or $type == "span" or $type == "font") {
                if ($isClosing) {
                    if ($stackLength == 0) {
                        # unmatched tag, don't do anything
                        $ret = $ret + $piece;
                    } else {
                        var bool popped = $stack[--$stackLength];

                        if ($popped) {
                            # matching tag began spoilers
                            $ret = $ret + get_close_spoiler();
                        } else {
                            # matching tag didn't begin spoilers
                            $ret = $ret + $piece;
                        }
                    }
                } else {
                    var bool spoiler = false;
                    var string spoilerType = "";

                    var string key;
                    var string value;

                    var string{} attributes;
                    foreach var int i (0 .. size $tokens) {
                        if ($tokens[$i] == "=") {
                            $key = $tokens[$i - 1];
                            $value = $tokens[$i + 1];
                            $attributes{$key} = $value;
                        }
                    }

                    if ($*spoiler_white_text) {
                        if ($type == "font" and $attributes{"color"}->lower() == "white") {
                            $spoiler = true;
                            $spoilerType = " spoiler-white";
                        }
                    }

                    if ($*spoiler_black_on_black) {
                        var string foreground = "black";
                        var string background = "white";

                        var string[] style = $attributes{"style"}->split(";");
                        var string[] temp;
                        foreach var string subpiece ($style) {
                            $temp = $subpiece->split(":");
                            $key = strip($temp[0]->lower());
                            $value = $temp[1]->lower();
                            $value = $value->replace("!important", "");
                            $value = strip($value);
                            if ($key == "background" or $key == "background-color") {
                                $background = $value;
                            } elseif ($key == "color") {
                                $foreground = $value;
                            }
                        }

                        if ($foreground == $background) {
                            $spoiler = true;
                            $spoilerType = " spoiler-black";
                        }
                    }

                    if ($*spoiler_special_tag_use) {
                        if ($attributes{$*spoiler_special_tag_name} != "") {
                            $spoiler = true;
                        }
                    }

                    if ($spoiler) {
                        $ret = $ret + get_open_spoiler(
                            $unique, string($index), $attributes{"title"}, $permalink, $spoilerType);
                        $index++;
                    } else {
                        $ret = $ret + $piece;
                    }

                    $stack[$stackLength++] = $spoiler;
                }
            } else {
                $ret = $ret + $piece;
            }
        } else {
            $ret = $ret + $piece;
        }
    }

    # check for leftover tags to close
    # this isn't necessary if the comment HTML is well-formed
    # but it's not clear whether we can count on that
    while ($stackLength > 0) {
        var bool popped = $stack[--$stackLength];

        if ($popped) {
            # matching tag began spoilers
            $ret = $ret + get_close_spoiler();
        } else {
            # assorted unclosed tags
            # the original HTML must have been malformed
        }
    }

    return $ret;
}

# add cuts to the given comment
function print_comment_with_cuts(Comment c) {
    if (not $*spoiler_are_cuts_enabled) {
        $c->print_text();
        return;
    }

    var Page p = get_page();
    var bool disabled = ($p.args{"spoilers"} == "disabled");

    if ($c.text_must_print_trusted or $disabled) {
        $c->print_text();
    } else {
        var string[] pieces = $c.permalink_url->split("#");
        var string permalink = $pieces[0];
        """<div class="comment-content">""";
        print safe add_cut_tags($c.text, "c-$c.talkid", $permalink);
        $c->print_edit_text();
        """</div>""";
    }
}

# add cuts to the given entry
function print_entry_with_cuts(Entry e) {
    if (not $*spoiler_are_cuts_enabled) {
        $e->print_text();
        return;
    }

    var Page p = get_page();
    var bool disabled = ($p.args{"spoilers"} == "disabled");

    if ($e.text_must_print_trusted or $disabled or not $*spoiler_cut_entries) {
        $e->print_text();
    } else {
        """<div class="entry-content">""";
        print safe add_cut_tags($e.text, "e-$e.itemid", $e.permalink_url);
        """</div>""";
    }
}

###############################################################################################
# CSS FOR SPOILER CUTS
###############################################################################################

function print_android_fix(string tag) {
    print """
/* hack for older android browsers */
/* from http://timpietrusky.com/advanced-checkbox-hack */

@media only screen and (-webkit-min-device-pixel-ratio:0) {
    $tag { 
        -webkit-animation: bugfix infinite 1s; 
    }

    @-webkit-keyframes bugfix { 
        from { padding: 0; } 
        to { padding: 0; } 
    }
}
""";
}

# prints the CSS used for the links to fix comment colors
function print_css_fix_colors(string checkboxDisplay) {
    print """

/* hack for Opera Mini to make links work */

.fix-colors-link {
    cursor: pointer;
}

.fix-colors {
    display: $checkboxDisplay;
}

.comment-fix-yes, .comment-fix-no {
    display: none;
}

.fix-colors:checked + .comment-wrapper > .comment .comment-content span,
.fix-colors:checked + .comment-wrapper > .comment .comment-content font, 
.fix-colors:checked + .comment-wrapper > .comment .comment-content div {
    background: none !important;
    color: inherit !important;
}

.fix-colors:checked + .comment-wrapper > .comment .comment-fix-no {
    display: inline;
}

.fix-colors:not(:checked) + .comment-wrapper > .comment .comment-fix-yes {
    display: inline;
}

""";
}

# prints the CSS used for the the hard link version of spoiler cuts
function print_css_hard_links(string checkboxDisplay, string linkOpenDisplay) {
    print """

/* SPOILER SETTINGS */

.spoiler {
    display: $checkboxDisplay;
}

.spoilerLink a {
    font-weight: bold;
}

/* FIX THE LINK IN OLDER BROWSERS */

.spoilerLink label {
    display: none;
}

.spoiler:checked + .spoilerCut > .spoilerLink label,
.spoiler:not(:checked) + .spoilerCut > .spoilerLink label {
    display: inline;
}

.spoiler:checked + .spoilerCut > .spoilerLink .fallback,
.spoiler:not(:checked) + .spoilerCut > .spoilerLink .fallback {
    display: none;
}

/* SETTINGS WHEN THE SPOILERS ARE CLOSED */

.spoilerHidden, .spoilerLink .close {
    display: none;
}

.spoilerLink, .spoilerLink .open {
    display: inline;
}

.spoilerShow .spoilerVisible {
    display: inline;
}
 
/* SETTINGS WHEN THE SPOILERS ARE OPEN */

.spoiler:checked + .spoilerCut > .spoilerHidden,
.spoiler:checked + .spoilerCut > .spoilerLink .close {
    display: inline;
}
 
.spoiler:checked + .spoilerCut > .spoilerLink {
    display: $linkOpenDisplay;
}

.spoiler:checked + .spoilerCut > .spoilerLink .open {
    display: none;
}

""";
}

function print_css_fallback(string checkboxDisplay, string linkOpenDisplay) {
    var string fallback = $*spoiler_fallback_color.as_string;
    if ($fallback == "") {
        $fallback = "black";
    }

    print """

/* hack for Opera Mini to make links work */

.spoilerLink .wrapper {
    cursor: pointer;
}

/* FALLBACK FOR OLDER BROWSERS */

.spoiler-black {
    background: $fallback;
    color: $fallback;
}

.spoiler-white {
    color: white;
}

.spoiler {
    display: $checkboxDisplay;
}

.spoilerCut {
    display: inline;
}

.spoilerLink {
    display: none;
}

/* RESET THE COLOR VALUES FOR NEWER BROWSERS */

.spoiler:checked + .spoiler-white,
.spoiler:checked + .spoiler-black,
.spoiler:not(:checked) + .spoiler-white,
.spoiler:not(:checked) + .spoiler-black {
    background: none !important;
    color: inherit !important;
}

/* STYLING FOR THE SPOILER CUT LINK */

.spoilerCut label {
    font-weight: bold;
}

/* SETTINGS WHEN THE SPOILERS ARE CLOSED */

.spoiler:checked + .spoilerCut > .spoilerHidden,
.spoiler:checked + .spoilerCut > .spoilerLink .close {
    display: none;
}

.spoiler:checked + .spoilerCut > .spoilerLink,
.spoiler:checked + .spoilerCut > .spoilerLink .open {
    display: inline;
}
 
/* SETTINGS WHEN THE SPOILERS ARE OPEN */

.spoiler:not(:checked) + .spoilerCut > .spoilerHidden,
.spoiler:not(:checked) + .spoilerCut > .spoilerLink .close {
    display: inline;
}
 
.spoiler:not(:checked) + .spoilerCut > .spoilerLink {
    display: $linkOpenDisplay;
}

.spoiler:not(:checked) + .spoilerCut > .spoilerLink .open {
    display: none;
}

""";
}

# prints the CSS used to handle spoiler cuts
function print_spoiler_css() {
    var string linkOpenDisplay = ($*spoiler_cut_show_open ? "inline" : "none");
    var string checkboxDisplay = ($*spoiler_show_checkboxes ? "inline" : "none");

    if ($*spoiler_fix_colors_comment) {
        print_android_fix(".comment");
        print_css_fix_colors($checkboxDisplay);
    }

    if ($*spoiler_are_cuts_enabled) {
        print_android_fix(".spoilerCut");

        if ($*spoiler_hard_links) {
            print_css_hard_links($checkboxDisplay, $linkOpenDisplay);
        } else {
            print_css_fallback($checkboxDisplay, $linkOpenDisplay);
        }
    }
}

###############################################################################################
# LAYOUT CUSTOMIZATIONS
###############################################################################################

property string layout_sidebar {
    values = "none|No Sidebars|one-left|One Sidebar, Left Side|one-right|One Sidebar, Right Side|two-left|Two Sidebars, Left Side|two-split|Two Sidebars, Both Sides|two-right|Two Sidebars, Right Side";
    des = "Sidebar arrangement:";
}

property string layout_sidebar_width_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    des = "Units for sidebar widths:";
}

property int layout_sidebar_width_first {
    des = "Width of first sidebar:";
}

property int layout_sidebar_width_second {
    des = "Width of second sidebar:";
}

property bool layout_header_show {
    des = "Show modules in header?";
}

property bool layout_header_vertical {
    des = "Display header modules in vertical configuration?";
}

# property int layout_header_column_count {
#     des = "Number of columns to split header into:";
#     note = """
#         Space will be evenly distributed across the different columns.
#     """;
# }

property bool layout_footer_show {
    des = "Show modules in footer?";
}

property bool layout_footer_vertical {
    des = "Display footer modules in vertical configuration?";
}

# property int layout_footer_column_count {
#     des = "Number of columns to split footer into:";
#     note = """
#         Space will be evenly distributed across the different columns.
#     """;
# }


###############################################################################################
# BOX DECORATION OPTIONS
###############################################################################################

property bool decoration_marked_header {
    des = "Add decorations to header:";
}

property bool decoration_marked_footer {
    des = "Add decorations to footer:";
}

property bool decoration_marked_sidebars {
    des = "Add decorations to sidebars:";
}

property bool decoration_marked_body {
    des = "Add decorations to elements in body:";
}

property bool decoration_marked_modules_header {
    des = "Subdivide section decorations in header:";
}

property bool decoration_marked_modules_footer {
    des = "Subdivide section decorations in footer:";
}

property bool decoration_marked_modules_sidebar {
    des = "Subdivide section decorations in sidebars:";
}

property string decoration_border_thickness_amount {
    grouped = 1;
}

property string decoration_border_thickness_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

property string[] decoration_border_thickness {
    des = "Border thickness:";
}

set decoration_border_thickness = ["decoration_border_thickness_amount", "decoration_border_thickness_units"];

property string decoration_border_style {
    values = "dotted|Dotted Border|dashed|Dashed Border|solid|Solid Border|double|Double Border";
    des = "Style for borders on marked sections:";
}

property Color decoration_border_color {
    des = "Border color";
}

property string decoration_border_radius_amount {
    grouped = 1;
}

property string decoration_border_radius_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

property string[] decoration_border_radius {
    des = "Corner curve:";
}

set decoration_border_radius = ["decoration_border_radius_amount", "decoration_border_radius_units"];

property bool decoration_shadow_show {
    des = "Show shadow on decorated boxes?";
}

property string[] decoration_shadow_horizontal {
    des = "Horizontal offset for shadow:";
}

property string decoration_shadow_horizontal_amount {
    grouped = 1;
}

property string decoration_shadow_horizontal_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

set decoration_shadow_horizontal = ["decoration_shadow_horizontal_amount", "decoration_shadow_horizontal_units"];

property string[] decoration_shadow_vertical {
    des = "Vertical offset for shadow:";
}

property string decoration_shadow_vertical_amount {
    grouped = 1;
}

property string decoration_shadow_vertical_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

set decoration_shadow_vertical = ["decoration_shadow_vertical_amount", "decoration_shadow_vertical_units"];

property string[] decoration_shadow_blur {
    des = "Shadow blur amount:";
}

property string decoration_shadow_blur_amount {
    grouped = 1;
}

property string decoration_shadow_blur_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

set decoration_shadow_blur = ["decoration_shadow_blur_amount", "decoration_shadow_blur_units"];

property string[] decoration_shadow_spread {
    des = "Shadow spread amount:";
}

property string decoration_shadow_spread_amount {
    grouped = 1;
}

property string decoration_shadow_spread_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

set decoration_shadow_spread = ["decoration_shadow_spread_amount", "decoration_shadow_spread_units"];

property Color decoration_shadow_color {
    des = "Shadow color";
}

property bool decoration_shadow_inset {
    des = "Shadow inset?";
}

property string decoration_box_padding_amount {
    grouped = 1;
}

property string decoration_box_padding_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

property string[] decoration_box_padding {
    des = "Decorated section padding:";
}

set decoration_box_padding = ["decoration_box_padding_amount", "decoration_box_padding_units"];

property string decoration_box_margin_amount {
    grouped = 1;
}

property string decoration_box_margin_units {
    values = "ex|ex|em|em|%|%|px|px|pt|pt";
    grouped = 1;
}

property string[] decoration_box_margin {
    des = "Decorated section margins:";
}

set decoration_box_margin = ["decoration_box_margin_amount", "decoration_box_margin_units"];


###############################################################################################
# DEFAULT VALUES FOR LAYOUT
###############################################################################################

set layout_sidebar = "none";
set layout_sidebar_width_units = "%";
set layout_sidebar_width_first = 20;
set layout_sidebar_width_second = 20;

set layout_header_show = true;
set layout_footer_show = false;
set layout_header_vertical = false;
set layout_footer_vertical = false;
# set layout_header_column_count = 1;
# set layout_footer_column_count = 1;

set decoration_box_padding_amount = "20";
set decoration_box_padding_units = "px";
set decoration_box_margin_amount = "0";
set decoration_box_margin_units = "px";

###############################################################################################
# PROPERTIES FOR COMMENT HEADER COLORS
###############################################################################################

# First Sidebar Header

property Color color_background_sidebar1 {
    des = "First sidebar background color";
}

property string[] image_background_sidebar1_group {
    des = "First sidebar background image";
    grouptype = "image";
}

set image_background_sidebar1_group = [ "image_background_sidebar1_url", "image_background_sidebar1_repeat", "image_background_sidebar1_position" ];

property string image_background_sidebar1_url {
    grouped = 1;
}
property string image_background_sidebar1_repeat {
    values = "repeat|tile image|no-repeat|don't tile|repeat-x|tile horizontally|repeat-y|tile vertically";
    grouped = 1;
}
property string image_background_sidebar1_position {
    values = "top left|top left|top center|top center|top right|top right|center left|center left|center center|center|center right|center right|bottom left|bottom left|bottom center|bottom center|bottom right|bottom right";
    grouped = 1;
    allow_other = 1;
}

# Second Sidebar Header

property Color color_background_sidebar2 {
    des = "Second sidebar background color";
}

property string[] image_background_sidebar2_group {
    des = "Second sidebar background image";
    grouptype = "image";
}

set image_background_sidebar2_group = [ "image_background_sidebar2_url", "image_background_sidebar2_repeat", "image_background_sidebar2_position" ];

property string image_background_sidebar2_url {
    grouped = 1;
}
property string image_background_sidebar2_repeat {
    values = "repeat|tile image|no-repeat|don't tile|repeat-x|tile horizontally|repeat-y|tile vertically";
    grouped = 1;
}
property string image_background_sidebar2_position {
    values = "top left|top left|top center|top center|top right|top right|center left|center left|center center|center|center right|center right|bottom left|bottom left|bottom center|bottom center|bottom right|bottom right";
    grouped = 1;
    allow_other = 1;
}

# First Comment Header

property Color color_comment_header1 {
    des = "Standard comment header color";
}

property string[] image_comment_header1_group {
    des = "Standard comment header image";
    grouptype = "image";
}

set image_comment_header1_group = [ "image_comment_header1_url", "image_comment_header1_repeat", "image_comment_header1_position" ];

property string image_comment_header1_url {
    grouped = 1;
}
property string image_comment_header1_repeat {
    values = "repeat|tile image|no-repeat|don't tile|repeat-x|tile horizontally|repeat-y|tile vertically";
    grouped = 1;
}
property string image_comment_header1_position {
    values = "top left|top left|top center|top center|top right|top right|center left|center left|center center|center|center right|center right|bottom left|bottom left|bottom center|bottom center|bottom right|bottom right";
    grouped = 1;
    allow_other = 1;
}

# Alternate Comment Header

property Color color_comment_header2 {
    des = "Alternate comment header color";
}

property string[] image_comment_header2_group {
    des = "Alternate comment header image";
    grouptype = "image";
}

set image_comment_header2_group = [ "image_comment_header2_url", "image_comment_header2_repeat", "image_comment_header2_position" ];

property string image_comment_header2_url {
    grouped = 1;
}
property string image_comment_header2_repeat {
    values = "repeat|tile image|no-repeat|don't tile|repeat-x|tile horizontally|repeat-y|tile vertically";
    grouped = 1;
}
property string image_comment_header2_position {
    values = "top left|top left|top center|top center|top right|top right|center left|center left|center center|center|center right|center right|bottom left|bottom left|bottom center|bottom center|bottom right|bottom right";
    grouped = 1;
    allow_other = 1;
}

# How to Alternate Colors

property bool color_comment_header_alternate {
    des = "Use alternate comment header colors.";
}

property bool color_comment_header_depth {
    des = "Use depth to alternate comment header colors.";
}

# Comment Link Size

property string font_comment_control {
    des = "Preferred font for comment control links";
    maxlength = 100;
    size = 25;
    note = "For example: Arial or \"Times New Roman\". Leave blank to use the default.";
}

property string font_comment_control_size {
    des = "Size of comment control link font";
    size = 3;
}

property string font_comment_control_units {
    des = "Units for comment control link size";
    values = "em|em|ex|ex|%|%|pt|pt|px|px";
}

###############################################################################################
# DEFAULT VALUES FOR COMMENT HEADER COLORS
###############################################################################################

set color_comment_header1 = "#BBDDFF";
set color_comment_header2 = "#AACCEE";
set color_comment_header_alternate = true;
set color_comment_header_depth = true;

###############################################################################################
# COMMENT LAYOUT SETTINGS
###############################################################################################

propgroup comment = "Comment Layout";

###############################################################################################

property bool comment_subject_show { grouped = 1; }
property int comment_subject_order { grouped = 1; }
property string comment_subject_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property bool comment_subject_opts_link {
    grouped = 1;
    label = "Make the subject line a link to the comment.";
}

property bool comment_subject_opts_always {
    grouped = 1;
    label = "Use placeholder text for empty subjects.";
}

property string[] comment_subject_group {
    des = "Comment subject.";
    grouptype = "module";
}

property string[] comment_subject_opts_group {
    grouptype = "moduleopts";
    grouped = 1;
}

set comment_subject_opts_group = [
    "comment_subject_opts_link",
    "comment_subject_opts_always",
];

set comment_subject_group = [
    "comment_subject_show",
    "comment_subject_order",
    "comment_subject_section",
    "comment_subject_opts_group"
];

function comment_print_subject(Comment c) {
    var string subject = $c->get_plain_subject();
    if ($subject != "" or $*comment_subject_opts_always) {
        print """<h4 class="comment-title">""";
        if ($*comment_subject_opts_link) {
            print """<a href="$c.permalink_url">""";
        }
        if ($subject == "") {
            print $*text_nosubject;
        } else {
            print $subject;
        }
        if ($*comment_subject_opts_link) {
            print """</a>""";
        }
        print """</h4>""";
    }
}

###############################################################################################

property bool comment_author_show { grouped = 1; }
property int comment_author_order { grouped = 1; }
property string comment_author_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_author_group {
    des = "Comment author.";
    grouptype = "module";
}

set comment_author_group = [
    "comment_author_show",
    "comment_author_order",
    "comment_author_section"
];

###############################################################################################

property bool comment_date_show { grouped = 1; }
property int comment_date_order { grouped = 1; }
property string comment_date_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property bool comment_date_opts_link {
    grouped = 1;
    label = "Make the date a link to the comment.";
}

property string[] comment_date_group {
    des = "Comment date.";
    grouptype = "module";
}

property string[] comment_date_opts_group {
    grouptype = "moduleopts";
    grouped = 1;
}

set comment_date_opts_group = [
    "comment_date_opts_link",
];

set comment_date_group = [
    "comment_date_show",
    "comment_date_order",
    "comment_date_section",
    "comment_date_opts_group"
];

function comment_print_date(Comment c) {
    print """<div class="comment-timestamp">""";
    if ($*comment_date_opts_link) {
        print """<a href="$c.permalink_url">""";
    }
    $c->print_time();
    if ($*comment_date_opts_link) {
         print """</a>""";
    }
    print """</div>""";
}

###############################################################################################

property bool comment_actions_show { grouped = 1; }
property int comment_actions_order { grouped = 1; }
property string comment_actions_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string comment_actions_opts_format {
    des = "The format for displaying comment management links.";
    grouped = 1;
    values = "icons|icons|text|text-only|";
}

property string[] comment_actions_group {
    des = "Comment management links.";
    grouptype = "module";
}

property string[] comment_actions_opts_group {
    grouptype = "moduleopts";
    grouped = 1;
}

set comment_actions_opts_group = [
    "comment_actions_opts_format",
];

set comment_actions_group = [
    "comment_actions_show",
    "comment_actions_order",
    "comment_actions_section",
    "comment_actions_opts_group"
];

###############################################################################################

property bool comment_links_show { grouped = 1; }
property int comment_links_order { grouped = 1; }
property string comment_links_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_links_group {
    des = "Comment thread links.";
    grouptype = "module";
}

property string[] comment_links_opts_group {
    grouptype = "moduleopts";
    grouped = 1;
}

set comment_links_opts_group = [];

set comment_links_group = [
    "comment_links_show",
    "comment_links_order",
    "comment_links_section",
    "comment_links_opts_group"
];

###############################################################################################

property bool comment_userpic_show { grouped = 1; }
property int comment_userpic_order { grouped = 1; }
property string comment_userpic_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property bool comment_userpic_opts_placeholder {
    grouped = 1;
    label = "Use a placeholder for comments with no userpic.";
}

property string[] comment_userpic_group {
    des = "Comment userpic.";
    grouptype = "module";
}

property string[] comment_userpic_opts_group {
    grouptype = "moduleopts";
    grouped = 1;
}

set comment_userpic_opts_group = [
    "comment_userpic_opts_placeholder",
];

set comment_userpic_group = [
    "comment_userpic_show",
    "comment_userpic_order",
    "comment_userpic_section",
    "comment_userpic_opts_group"
];

###############################################################################################

property bool comment_select_show { grouped = 1; }
property int comment_select_order { grouped = 1; }
property string comment_select_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_select_group {
    des = "Select comment checkbox.";
    grouptype = "module";
}

set comment_select_group = [
    "comment_select_show",
    "comment_select_order",
    "comment_select_section"
];

###############################################################################################

property bool comment_metadata_show { grouped = 1; }
property int comment_metadata_order { grouped = 1; }
property string comment_metadata_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_metadata_group {
    des = "Comment metadata (e.g. IP address).";
    grouptype = "module";
}

set comment_metadata_group = [
    "comment_metadata_show",
    "comment_metadata_order",
    "comment_metadata_section"
];

###############################################################################################

property bool comment_emoticon_show { grouped = 1; }
property int comment_emoticon_order { grouped = 1; }
property string comment_emoticon_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_emoticon_group {
    des = "Comment emoticon.";
    grouptype = "module";
}

set comment_emoticon_group = [
    "comment_emoticon_show",
    "comment_emoticon_order",
    "comment_emoticon_section"
];

###############################################################################################

property bool comment_posted_show { grouped = 1; }
property int comment_posted_order { grouped = 1; }
property string comment_posted_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_posted_group {
    des = "Comment posted message.";
    grouptype = "module";
}

set comment_posted_group = [
    "comment_posted_show",
    "comment_posted_order",
    "comment_posted_section"
];

###############################################################################################

property bool comment_reply_show { grouped = 1; }
property int comment_reply_order { grouped = 1; }
property string comment_reply_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_reply_group {
    des = "Comment quick reply box.";
    grouptype = "module";
}

set comment_reply_group = [
    "comment_reply_show",
    "comment_reply_order",
    "comment_reply_section"
];

###############################################################################################

property bool comment_fix1_show { grouped = 1; }
property int comment_fix1_order { grouped = 1; }
property string comment_fix1_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_fix1_group {
    des = "Comment color fixing link.  (First version.)";
    grouptype = "module";
}

set comment_fix1_group = [
    "comment_fix1_show",
    "comment_fix1_order",
    "comment_fix1_section"
];

###############################################################################################

property bool comment_fix2_show { grouped = 1; }
property int comment_fix2_order { grouped = 1; }
property string comment_fix2_section {
    grouped = 1;
    values = "header-left|Left Header|header-center|Center Header|header-right|Right Header|footer|Footer";
}

property string[] comment_fix2_group {
    des = "Comment color fixing link.  (Second version.)";
    grouptype = "module";
}

set comment_fix2_group = [
    "comment_fix2_show",
    "comment_fix2_order",
    "comment_fix2_section"
];

function comment_print_fix(Comment c) {
    print """<span class="fix-colors-link">""";
    print """<a href="#cmt$c.talkid">""";
    print """<label for="fix-colors-$c.talkid">""";
    print """<span class="comment-fix-yes">""";
    print safe $*spoiler_fix_colors_text;
    print """</span>""";
    print """<span class="comment-fix-no">""";
    print safe $*spoiler_reset_colors_text;
    print """</span>""";
    print """</label>""";
    print """</a>""";
    print """</span>""";
}

###############################################################################################

set comment_userpic_order = 0;
set comment_subject_order = 1;
set comment_emoticon_order = 2;
set comment_author_order = 3;
set comment_date_order = 4;
set comment_metadata_order = 5;
set comment_posted_order = 6;
set comment_actions_order = 7;
set comment_links_order = 8;
set comment_select_order = 9;
set comment_reply_order = 10;
set comment_fix1_order = 11;
set comment_fix2_order = 12;

set comment_userpic_show = true;
set comment_subject_show = true;
set comment_emoticon_show = true;
set comment_author_show = true;
set comment_date_show = true;
set comment_metadata_show = true;
set comment_posted_show = true;
set comment_actions_show = true;
set comment_links_show = true;
set comment_select_show = true;
set comment_reply_show = true;
set comment_fix1_show = false;
set comment_fix2_show = false;

set comment_userpic_section = "header-left";
set comment_subject_section = "header-center";
set comment_emoticon_section = "header-center";
set comment_author_section = "header-center";
set comment_date_section = "header-center";
set comment_metadata_section = "header-center";
set comment_posted_section = "header-center";
set comment_actions_section = "header-right";
set comment_links_section = "footer";
set comment_select_section = "footer";
set comment_reply_section = "footer";
set comment_fix1_section = "header-right";
set comment_fix2_section = "footer";

###############################################################################################

property string[]{} comment_sections {
    noui = 1;
}

function comment_init() {
    var string[][]{} sections;
    var int[]{} counts;

    if ($*comment_subject_show) {
        var int count = $counts{$*comment_subject_section}[$*comment_subject_order];
        $sections{$*comment_subject_section}[$*comment_subject_order][$count] = "subject";
        $counts{$*comment_subject_section}[$*comment_subject_order] = $count + 1;
    }

    if ($*comment_author_show) {
        var int count = $counts{$*comment_author_section}[$*comment_author_order];
        $sections{$*comment_author_section}[$*comment_author_order][$count] = "author";
        $counts{$*comment_author_section}[$*comment_author_order] = $count + 1;
    }

    if ($*comment_date_show) {
        var int count = $counts{$*comment_date_section}[$*comment_date_order];
        $sections{$*comment_date_section}[$*comment_date_order][$count] = "date";
        $counts{$*comment_date_section}[$*comment_date_order] = $count + 1;
    }

    if ($*comment_actions_show) {
        var int count = $counts{$*comment_actions_section}[$*comment_actions_order];
        $sections{$*comment_actions_section}[$*comment_actions_order][$count] = "actions";
        $counts{$*comment_actions_section}[$*comment_actions_order] = $count + 1;
    }

    if ($*comment_links_show) {
        var int count = $counts{$*comment_links_section}[$*comment_links_order];
        $sections{$*comment_links_section}[$*comment_links_order][$count] = "links";
        $counts{$*comment_links_section}[$*comment_links_order] = $count + 1;
    }

    if ($*comment_userpic_show) {
        var int count = $counts{$*comment_userpic_section}[$*comment_userpic_order];
        $sections{$*comment_userpic_section}[$*comment_userpic_order][$count] = "userpic";
        $counts{$*comment_userpic_section}[$*comment_userpic_order] = $count + 1;
    }

    if ($*comment_select_show) {
        var int count = $counts{$*comment_select_section}[$*comment_select_order];
        $sections{$*comment_select_section}[$*comment_select_order][$count] = "select";
        $counts{$*comment_select_section}[$*comment_select_order] = $count + 1;
    }

    if ($*comment_metadata_show) {
        var int count = $counts{$*comment_metadata_section}[$*comment_metadata_order];
        $sections{$*comment_metadata_section}[$*comment_metadata_order][$count] = "metadata";
        $counts{$*comment_metadata_section}[$*comment_metadata_order] = $count + 1;
    }

    if ($*comment_emoticon_show) {
        var int count = $counts{$*comment_emoticon_section}[$*comment_emoticon_order];
        $sections{$*comment_emoticon_section}[$*comment_emoticon_order][$count] = "emoticon";
        $counts{$*comment_emoticon_section}[$*comment_emoticon_order] = $count + 1;
    }

    if ($*comment_posted_show) {
        var int count = $counts{$*comment_posted_section}[$*comment_posted_order];
        $sections{$*comment_posted_section}[$*comment_posted_order][$count] = "posted";
        $counts{$*comment_posted_section}[$*comment_posted_order] = $count + 1;
    }

    if ($*comment_reply_show) {
        var int count = $counts{$*comment_reply_section}[$*comment_reply_order];
        $sections{$*comment_reply_section}[$*comment_reply_order][$count] = "reply";
        $counts{$*comment_reply_section}[$*comment_reply_order] = $count + 1;
    }

    $*spoiler_fix_colors_comment = false;

    if ($*comment_fix1_show) {
        var int count = $counts{$*comment_fix1_section}[$*comment_fix1_order];
        $sections{$*comment_fix1_section}[$*comment_fix1_order][$count] = "fix";
        $counts{$*comment_fix1_section}[$*comment_fix1_order] = $count + 1;
        $*spoiler_fix_colors_comment = true;
    }

    if ($*comment_fix2_show) {
        var int count = $counts{$*comment_fix2_section}[$*comment_fix2_order];
        $sections{$*comment_fix2_section}[$*comment_fix2_order][$count] = "fix";
        $counts{$*comment_fix2_section}[$*comment_fix2_order] = $count + 1;
        $*spoiler_fix_colors_comment = true;
    }

    foreach var string section ($sections) {
        var int count = 0;
        foreach var string[] group ($sections{$section}) {
            foreach var string item ($group) {
                if ($item != "") {
                    $*comment_sections{$section}[$count] = $item;
                    $count = $count + 1;
                }
            }
        }
    }
}

function comment_print_section(string section, Comment c, bool multiform, bool posted) {
    foreach var string item ($*comment_sections{$section}) {
        if ($item == "subject") {
            comment_print_subject($c);
        } elseif ($item == "author") {
            $c->print_poster();
        } elseif ($item == "date") {
            comment_print_date($c);
        } elseif ($item == "actions") {
            $c->print_management_links();
        } elseif ($item == "links") {
            $c->print_interaction_links();
        } elseif ($item == "userpic") {
            $c->print_userpic();
        } elseif ($item == "select") {
            if ($multiform) {
                print """<span class="multiform-checkbox">""";
                print safe " <label for='ljcomsel_$c.talkid'>$*text_multiform_check</label> ";
                $c->print_multiform_check();
                print """</span>""";
            }
        } elseif ($item == "metadata") {
            $c->print_metadata();
        } elseif ($item == "emoticon") {
            $c->print_metatypes();
        } elseif ($item == "posted") {
            if ($posted) {
                print safe "<div class='comment-posted'>$*text_comment_posted</div>";
            }
        } elseif ($item == "reply") {
            $c->print_reply_container();
        } elseif ($item == "fix") {
            comment_print_fix($c);
        }
    }
}

function prop_init() {
    comment_init();

    $*comment_management_links = $*comment_actions_opts_format;
    $*all_commentsubjects = $*comment_subject_opts_always;

    $*spoiler_are_cuts_enabled = ($*spoiler_white_text or $*spoiler_black_on_black or $*spoiler_special_tag_use);
}


###############################################################################################
# MODIFIED VERSIONS OF CORE FUNCTIONS
###############################################################################################

function open_module(string intname, string title, string headlink_url, bool nocontent)
"Opens up a module for printing, using the appropriate HTML/CSS."
{
    print safe """<div class="module-$intname module">""";
    print safe """<div class="inner">""";
    if ($title != "") {
        """<h2 class="module-header">""";
        if ($headlink_url != "") { print safe """<a href="$headlink_url">"""; }
        print safe $title;
        if ($headlink_url != "") { """</a>"""; }
        "</h2>\n";
    }
    if (not $nocontent) {
        println """<div class="module-content">""";
    }
}


# override the close_module procedure to
# - remove the space between modules
# - add a closing tag for the .inner tag
function close_module(bool nocontent) {
    print "</div></div>";
    if (not $nocontent) { print "</div>"; }
}

function print_comment_customizable(Comment c, bool multiform, bool posted) {
    if ($*spoiler_fix_colors_comment) {
        print """<input type="checkbox" id="fix-colors-$c.talkid" class="fix-colors">""";
    }

    $c->print_wrapper_start();

    """<div class="header">\n""";
    """<div class="inner">\n""";

    """<div class="left">\n""";
    comment_print_section("header-left", $c, $multiform, $posted);
    """</div>\n""";

    """<div class="right">\n""";
    comment_print_section("header-right", $c, $multiform, $posted);
    """</div>\n""";

    """<div class="center">\n""";
    comment_print_section("header-center", $c, $multiform, $posted);
    """</div>\n""";

    """<div class="clear"></div>\n""";
    """</div>\n""";
    """</div>\n""";

    """<div class="contents">\n""";
    """<div class="inner">\n""";

    print_comment_with_cuts($c);

    """</div>\n""";
    """</div>\n""";

    """<div class="footer">\n""";
    """<div class="inner">\n""";
    comment_print_section("footer", $c, $multiform, $posted);
    "</div>\n</div>\n";

    $c->print_wrapper_end();
}

# a single function for printing comments
# merges the functionality of ReplyPage::print_comment and EntryPage::print_comment
# for greater ease of comment customizability
function print_comment(Page p, Comment c, bool isStandard) {
    var EntryPage e;
    if ($isStandard) {
        $e = $p as EntryPage;
    }

    if ($*spoiler_fix_colors_comment) {
        print """<input type="checkbox" id="fix-colors-$c.talkid" class="fix-colors">""";
    }

    $c->print_wrapper_start();

    """<div class="header">\n""";
    """<div class="inner">\n""";

    $c->print_userpic();

    """<div class="controls">\n""";

    if ($*spoiler_fix_colors_comment) {
        comment_print_fix($c);
    }

    $c->print_management_links();

    if ($isStandard and $e.multiform_on) {
        print """<span class="multiform-checkbox">""";
        print safe " <label for='ljcomsel_$c.talkid'>$*text_multiform_check</label> ";
        $c->print_multiform_check();
        print """</span>""";
    }

    """</div>\n""";

    """<div class="center">\n""";

    var string subject = $c->get_plain_subject();
    if ($subject != "" or $*all_commentsubjects) {
        print """<h4 class="comment-title">""";
        if ($subject == "") {
            print $*text_nosubject;
        } else {
            print $subject;
        }
        print """</h4>""";
    }

    $c->print_metatypes();
    $c->print_poster();
    """<div class="comment-timestamp"><a href="$c.permalink_url">""";
    $c->print_time();
    """</a></div>""";
    $c->print_metadata();

    if ( $isStandard and $c.comment_posted ) {
        print safe "<div class='comment-posted'>$*text_comment_posted</div>";
    }

    """</div>\n""";

    """<div class="clear"></div>\n""";
    """</div>\n""";
    """</div>\n""";

    """<div class="contents">\n""";
    """<div class="inner">\n""";

    print_comment_with_cuts($c);

    """</div>\n""";
    """</div>\n""";
    """<div class="footer">\n""";
    """<div class="inner">\n""";
    $c->print_interaction_links();
    $c->print_reply_container();
    "</div>\n</div>\n";
    $c->print_wrapper_end();
}

function ReplyPage::print_comment (Comment c) {
    print_comment($this, $c, false);
    # print_comment_customizable($c, false, false);
}

function EntryPage::print_comment (Comment c) {
    print_comment($this, $c, true);
    # print_comment_customizable($c, $this.multiform_on, $c.comment_posted);
}

function EntryPage::print_comment_partial (Comment c) {
    $c->print_wrapper_start();

    if ($c.deleted or $c.fromsuspended or $c.screened_noshow) {
        if ($c.deleted) {
            print $*text_deleted;
        } elseif ($c.fromsuspended) {
            print $*text_fromsuspended;
        } elseif ($c.screened_noshow) {
            print $*text_screened;
        }

        if ($c.hide_children) {
            var Link expand_link = $c->get_link("expand_comments");
            if (defined $expand_link) {
                print " (";
                $c->print_expand_link();
                print ")";
            }
        }
    } else {
        var string poster = defined $c.poster ? $c.poster->as_string() : "<i>$*text_poster_anonymous</i>";

        $c->print_subject(); " - ";
        $c->print_poster(); " - ";
        $c->print_time();
        var Link expand_link = $c->get_link("expand_comments");
        if (defined $expand_link) {
            " - "; $c->print_expand_link();
            if ( $c.comment_posted ) {
                print safe " <span class='comment-posted'>$*text_comment_posted</span>";
            }
        }
    }

    $c->print_wrapper_end();
}

function Page::print_entry(Entry e)
{
    $e->print_wrapper_start();
    """<div class="header">\n""";
    """<div class="inner">\n""";

    $e->print_subject();
    $e->print_metatypes();
    $e->print_time();
    """</div>\n""";
    """</div>\n""";
    """<div>\n""";
    """<div class="contents">\n""";
    """<div class="inner">\n""";

    """<div class="entry-poster-info">\n""";
    $e->print_userpic();
    $e->print_poster();
    """</div>\n""";

    if ($*entry_metadata_position == "top") { $e->print_metadata(); }
    print_entry_with_cuts($e);
    if ($*entry_metadata_position == "bottom") { $e->print_metadata(); }

    """<div class="clear"></div>\n""";

    """</div>\n""";
    """</div>\n""";
    """</div>\n""";

    """<div class="footer">\n""";
    """<div class="inner">\n""";
    $e->print_tags();
    $this->print_entry_footer($e);
    "</div>\n</div>\n";

    $e->print_wrapper_end();

}

function EntryPage::print_comment_section(Entry e) {
   "<div id='comments'><div class='inner'>";
   $.comment_pages->print({ "anchor" => "comments", "class" => "comment-pages toppages" });
   if ( $e.comments.comments_disabled_maintainer ) {
        """<div class='comments-message'>$*text_comments_disabled_maintainer</div>""";
   }
   if ($.comment_pages.total_subitems > 0) {
        $.comment_nav->print({ "class" => "comment-pages toppages" });
        $this->print_multiform_start();
   }
   $this->print_comments($.comments);
   if ($.comment_pages.total_subitems > 0) {
        "<div class='bottomcomment'>";
        $e->print_management_links();
        $e->print_interaction_links("bottomcomment");
        $this->print_reply_container({ "target" => "bottomcomment" });
        $this->print_multiform_actionline();
        $this->print_multiform_end();
        "</div>";
   }
   $.comment_pages->print({ "anchor" => "comments", "class" => "comment-pages bottompages" });
   if ($.comment_pages.total_subitems > 0) {
        $.comment_nav->print({ "class" => "comment-pages bottompages" });
   }
    "</div></div>";
}

function Page::print()
{
    """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n""";
    """<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n""";
    """<head profile="http://www.w3.org/2006/03/hcard http://purl.org/uF/hAtom/0.1/ http://gmpg.org/xfn/11">\n""";
    $this->print_head();
    $this->print_stylesheets();
    $this->print_head_title();

    """</head>""";
    $this->print_wrapper_start();
    $this->print_control_strip();

    """<div id="canvas">""";
        """<div class="inner">""";
            """<div id="header">""";
                """<div class="inner">""";
                    """<div id="title-container">""";
                        $this->print_global_title();
                        $this->print_global_subtitle();
                        $this->print_title();
                    """</div>""";
                    if ($*layout_header_show) {
                        if ($*layout_header_vertical) {
                            """<div id="header-modules" class="vertical">""";
                        } else {
                            """<div id="header-modules" class="horizontal">""";
                        }

                        $this->print_module_section("head");
                        """</div>""";
                    }
    """
                </div>
            </div>
            <div id="content">
                <div class="inner">
    """;
                    if ($*layout_sidebar != "none") {
                        """<div id="sidebar1"><div class="inner">""";
                        $this->print_module_section("sidebar1");
                        """</div></div>""";
                    }

                    if ($*layout_sidebar == "two-left" or $*layout_sidebar == "two-right" or $*layout_sidebar == "two-split") {
                        """<div id="sidebar2"><div class="inner">""";
                        $this->print_module_section("sidebar2");
                        """</div></div>""";
                    }

                    """<div id="primary"><div class="inner">""";
                    $this->print_body();
                    """<div class="clear"></div>""";
                    """</div></div>""";

    """
                    <div class="clear"></div>
                </div>
            </div>
            <div id="footer">
                <div class="inner">
    """;
                    if ($*layout_footer_show) {
                        if ($*layout_footer_vertical) {
                            """<div id="footer-modules" class="vertical">""";
                        } else {
                            """<div id="footer-modules" class="horizontal">""";
                        }

                        $this->print_module_section("foot");
                        """</div>""";
                    }

                    print safe """<div class="page-top"><a href="#">$*text_page_top</a></div>""";
    """
                </div>
            </div><!-- here -->
        </div>
    """;

    """
    </div>
    """;
    $this->print_wrapper_end();
    """</html>""";
}

###############################################################################################
# PRINT OUT THE STYLESHEET FOR THIS
###############################################################################################

function print_layout_css() {
    var string sidebar1 = "none";
    var string sidebar2 = "none";

    var int leftMargin = 0;
    var int rightMargin = 0;

    if ($*layout_sidebar == "one-left") {
        $sidebar1 = "left";
        $leftMargin = $leftMargin + $*layout_sidebar_width_first;
    } elseif ($*layout_sidebar == "one-right") {
        $sidebar1 = "right";
        $rightMargin = $rightMargin + $*layout_sidebar_width_first;
    } elseif ($*layout_sidebar == "two-left") {
        $sidebar1 = "left";
        $sidebar2 = "left";
        $leftMargin = $leftMargin + $*layout_sidebar_width_first;
        $leftMargin = $leftMargin + $*layout_sidebar_width_second;
    } elseif ($*layout_sidebar == "two-split") {
        $sidebar1 = "left";
        $sidebar2 = "right";
        $leftMargin = $leftMargin + $*layout_sidebar_width_first;
        $rightMargin = $rightMargin + $*layout_sidebar_width_second;
    } elseif ($*layout_sidebar == "two-right") {
        $sidebar1 = "right";
        $sidebar2 = "right";
        $rightMargin = $rightMargin + $*layout_sidebar_width_first;
        $rightMargin = $rightMargin + $*layout_sidebar_width_second;
    }

    if ($sidebar1 != "none") {
        print """
#sidebar1 {
    float: $sidebar1;
    width: $*layout_sidebar_width_first$*layout_sidebar_width_units;
    overflow: hidden;
}
""";
    }

    if ($sidebar2 != "none") {
        print """
#sidebar2 {
    float: $sidebar2;
    width: $*layout_sidebar_width_second$*layout_sidebar_width_units;
    overflow: hidden;
}
""";
    }

    print """
#primary {
    margin-left: $leftMargin$*layout_sidebar_width_units;
    margin-right: $rightMargin$*layout_sidebar_width_units;
}
""";
}

function print_font_css() {
    var string page_font = generate_font_css(
        "", $*font_base, $*font_fallback,
        $*font_base_size, $*font_base_units);
    var string page_title_font = generate_font_css(
        $*font_journal_title, $*font_base, $*font_fallback,
        $*font_journal_title_size, $*font_journal_title_units);
    var string page_subtitle_font = generate_font_css(
        $*font_journal_subtitle, $*font_base, $*font_fallback,
        $*font_journal_subtitle_size, $*font_journal_subtitle_units);
    var string entry_title_font = generate_font_css(
        $*font_entry_title, $*font_base, $*font_fallback,
        $*font_entry_title_size, $*font_entry_title_units);
    var string comment_title_font = generate_font_css(
        $*font_comment_title, $*font_base, $*font_fallback,
        $*font_comment_title_size, $*font_comment_title_units);
    var string comment_control_font = generate_font_css(
        $*font_comment_control, $*font_base, $*font_fallback,
        $*font_comment_control_size, $*font_comment_control_units);
    var string module_font = generate_font_css(
        $*font_module_text, $*font_base, $*font_fallback,
        $*font_module_text_size, $*font_module_text_units);
    var string module_title_font = generate_font_css(
        $*font_module_heading, $*font_base, $*font_fallback,
        $*font_module_heading_size, $*font_module_heading_units);

    print """
body { $page_font }
#title { $page_title_font }
#pagetitle { $page_subtitle_font }
.entry-title { $entry_title_font }
.full .comment-title { $comment_title_font }
.partial .comment-title { $page_font }
.module { $module_font }
.module-header { $module_title_font }
.comment-interaction-links { $comment_control_font }
.comment-management-links { $comment_control_font }
.fix-colors-link { $comment_control_font }
""";
}

function print_background_css() {
    var string page_background = generate_background_css(
        $*image_background_page_url,
        $*image_background_page_repeat,
        $*image_background_page_position,
        $*color_page_background);
    var string header_background = generate_background_css(
        $*image_background_header_url,
        $*image_background_header_repeat,
        $*image_background_header_position,
        $*color_header_background);

    if ($*image_background_header_height > 0) {
        $header_background = """
            $header_background
            height: """ + $*image_background_header_height + """px;""";
    }

    var string footer_background = generate_background_css(
        "",
        "",
        "",
        $*color_footer_background);
    var string entry_background = generate_background_css(
        $*image_background_entry_url,
        $*image_background_entry_repeat,
        $*image_background_entry_position,
        $*color_entry_background);
    var string module_background = generate_background_css(
        $*image_background_module_url,
        $*image_background_module_repeat,
        $*image_background_module_position,
        $*color_module_background);

    var string sidebar1_background = generate_background_css(
        $*image_background_sidebar1_url,
        $*image_background_sidebar1_repeat,
        $*image_background_sidebar1_position,
        $*color_background_sidebar1);
    var string sidebar2_background = generate_background_css(
        $*image_background_sidebar2_url,
        $*image_background_sidebar2_repeat,
        $*image_background_sidebar2_position,
        $*color_background_sidebar2);

    var string comment_background1 = generate_background_css(
        $*image_comment_header1_url,
        $*image_comment_header1_repeat,
        $*image_comment_header1_position,
        $*color_comment_header1);
    var string comment_background2 = generate_background_css(
        $*image_comment_header2_url,
        $*image_comment_header2_repeat,
        $*image_comment_header2_position,
        $*color_comment_header2);

    var string decorations = "";

    if ($*decoration_border_radius_amount != "") {
        $decorations = $decorations + "border-radius: ";
        $decorations = $decorations + "$*decoration_border_radius_amount";
        $decorations = $decorations + "$*decoration_border_radius_units; ";
    }

    if ($*decoration_border_thickness_amount != "") {
        $decorations = $decorations + "border: ";
        $decorations = $decorations + "$*decoration_border_thickness_amount";
        $decorations = $decorations + "$*decoration_border_thickness_units ";
        $decorations = $decorations + "$*decoration_border_style ";
        $decorations = $decorations + "$*decoration_border_color; ";
    }

    if ($*decoration_shadow_show) {
        $decorations = $decorations + "box-shadow: ";
        $decorations = $decorations + "$*decoration_shadow_horizontal_amount";
        $decorations = $decorations + "$*decoration_shadow_horizontal_units ";
        $decorations = $decorations + "$*decoration_shadow_vertical_amount";
        $decorations = $decorations + "$*decoration_shadow_vertical_units ";
        $decorations = $decorations + "$*decoration_shadow_blur_amount";
        $decorations = $decorations + "$*decoration_shadow_blur_units ";
        $decorations = $decorations + "$*decoration_shadow_spread_amount";
        $decorations = $decorations + "$*decoration_shadow_spread_units ";
        $decorations = $decorations + "$*decoration_shadow_color";
        $decorations = $decorations + ($*decoration_shadow_inset ? " inset; " : "; ");
    }

    var string padding = "$*decoration_box_padding_amount$*decoration_box_padding_units";
    var string margin = "$*decoration_box_margin_amount$*decoration_box_margin_units";

    var string all = "padding: $padding; margin: $margin; ";

    var string sidebar1 = "";
    var string sidebar2 = "";
    if ($*layout_sidebar == "one-left") {
        $sidebar1 = "padding: $padding; margin-left: $margin; margin-bottom: $margin;";
    } elseif ($*layout_sidebar == "one-right") {
        $sidebar1 = "padding: $padding; margin-right: $margin; margin-bottom: $margin;";
    } elseif ($*layout_sidebar == "two-left") {
        $sidebar1 = "padding: $padding; margin-left: $margin; margin-bottom: $margin;";
        $sidebar2 = "padding: $padding; margin-left: $margin; margin-bottom: $margin;";
    } elseif ($*layout_sidebar == "two-split") {
        $sidebar1 = "padding: $padding; margin-left: $margin; margin-bottom: $margin;";
        $sidebar2 = "padding: $padding; margin-right: $margin; margin-bottom: $margin;";
    } elseif ($*layout_sidebar == "two-right") {
        $sidebar1 = "padding: $padding; margin-right: $margin; margin-bottom: $margin;";
        $sidebar2 = "padding: $padding; margin-right: $margin; margin-bottom: $margin;";
    }

    print """body { $page_background }\n""";

    if ($*decoration_marked_header) {
        if ($*decoration_marked_modules_header) {
            print """#title-container { $header_background }\n""";
            print """#header .module .inner, #title-container { $decorations $all }\n""";
        } else {
            print """#header > .inner { $header_background $decorations $all }\n""";
        }
    } else {
        print """#header { $header_background $all }\n""";
    }

    if ($*decoration_marked_footer) {
        if ($*decoration_marked_modules_footer) {
            print """#footer .module .inner { $decorations $all }\n""";
        } else {
            print """#footer > .inner { $footer_background $decorations $all }\n""";
        }
    } else {
        print """#footer { $footer_background $all }\n""";
    }

    if ($*decoration_marked_body) {
        print """.header, .contents, .footer,\n""";
        print """.comment-pages, .bottomcomment, .navigation,\n""";
        print """.partial .comment, .day-date, #archive-month .month {\n""";
        print """$entry_background $decorations $all\n""";
        print """}\n""";
    } else {
        print """#primary > .inner { $entry_background $all }\n""";
    }

    if ($*decoration_marked_sidebars) {
        if ($*decoration_marked_modules_sidebar) {
            print """#sidebar1 .module .inner { $decorations $sidebar1 }\n""";
            print """#sidebar2 .module .inner { $decorations $sidebar2 }\n""";
        } else {
            print """#sidebar1 > .inner { $sidebar1_background $decorations $sidebar1 }\n""";
            print """#sidebar2 > .inner { $sidebar2_background $decorations $sidebar2 }\n""";
        }
    } else {
        print """#sidebar1 { $sidebar1_background $sidebar1 }\n""";
        print """#sidebar2 { $sidebar2_background $sidebar2 }\n""";
    }

    print """.module .inner { $module_background }\n""";
    print """.comment .header { $comment_background1 }\n""";

    if ($*color_comment_header_alternate) {
        if ($*color_comment_header_depth) {
            print """.comment-depth-even > .dwexpcomment .header { $comment_background2 }\n""";
            print """.comment-depth-odd > .dwexpcomment .header { $comment_background1 }\n""";
        } else {
            print """.comment-wrapper-even .header { $comment_background2 }\n""";
            print """.comment-wrapper-odd .header { $comment_background1 }\n""";
        }
    }
}

function print_text_color(string class, Color c) {
    if ($c.as_string != "") {
        print "$class { color: $c; }\n";
    }
}

function print_link_colors(string class, Color normal, Color active, Color hover, Color visited) {
    print_text_color("$class", $normal);
    print_text_color("$class:active", $active);
    print_text_color("$class:hover", $hover);
    print_text_color("$class:visited", $visited);
}

function print_link_css() {
    print_link_colors("a",
        $*color_page_link,
        $*color_page_link_active,
        $*color_page_link_hover,
        $*color_page_link_visited);

    print_link_colors("#footer a",
        $*color_footer_link,
        $*color_footer_link_active,
        $*color_footer_link_hover,
        $*color_footer_link_visited);

    print_link_colors(".module a",
        $*color_module_link,
        $*color_module_link_active,
        $*color_module_link_hover,
        $*color_module_link_visited);

    print_link_colors(".entry a",
        $*color_entry_link,
        $*color_entry_link_active,
        $*color_entry_link_hover,
        $*color_entry_link_visited);

    print_link_colors(".entry .footer a",
        $*color_entry_interaction_links,
        $*color_entry_interaction_links_active,
        $*color_entry_interaction_links_hover,
        $*color_entry_interaction_links_visited);
}

function print_color_css() {
    print_text_color("body", $*color_page_text);
    print_text_color(".entry", $*color_entry_text);
    print_text_color(".entry-title", $*color_entry_title);
    print_text_color(".module", $*color_module_text);
    print_text_color(".module-title", $*color_module_title);
    print_text_color("#title-container", $*color_page_title);
    print_text_color(".comment-title", $*color_comment_title);
}

function Page::print_default_stylesheet()
{
    print """

#canvas * {
    box-sizing:border-box;
    -moz-box-sizing:border-box;
}

h1, h2, h3, h4, body {
    padding: 0px;
    margin: 0px;
}

""";

    print_spoiler_css();
    print_layout_css();

    print_font_css();
    print_background_css();
    print_link_css();
    print_color_css();

    if (not $*comment_userpic_opts_placeholder) {
        print """.no-userpic .comment .userpic { display: none; }""";
    }

    print """

.navigation.empty {
    display: none;
}

#canvas {
    margin: 0px $*margins_size$*margins_unit;
}

.horizontal .module-list {
    padding: 0px;
    margin: 0px;
}

.horizontal .module-list-item {
    display: inline;
}

.comment-pages {
    text-align: center;
}

.page-recent #primary .separator-after {
    background: black;
    height: 1px;
    margin: 10px;
}

.comment-pages > b:first-child {
    display: block;
}

.year {
    text-align: center;
}

.year .month-wrapper {
    display: inline-block;
    vertical-align: top;
}

.month {
    padding: 10px;
    border-spacing: 4px;
}

.month .header {
    text-align: center;
}

.month .day {
    width: 35px;
    height: 45px;
    vertical-align: top;
    padding: 5px;
}

.month .day .label {
    padding: 0px;
    margin: 0px;
    display: block;
    text-align: right;
}

.month .day p {
    padding: 0px;
    margin: 0px;
    text-align: center;
}

.entry-interaction-links {
    font-weight: bold;
    text-align: center;
    margin: 0px;
    padding: 10px 0px;
}

.entry-interaction-links li:before {
    content: " | ";
}

.entry-interaction-links .first-item:before {
    content: "";
}

.entry-interaction-links:before {
    content: "( ";
}

.entry-interaction-links:after {
    content: " )";
}

.entry-interaction-links li {
    display: inline;
}

.entry-management-links {
    text-align: center;     
    margin: 0px;
    padding: 10px 0px;
}

.entry-management-links li {
    display: inline;
}

.comment-management-links {
    margin: 0px;
}

.comment-management-links li {
    display: inline;
}

.comment-interaction-links {
    padding: 5px 0px;
    margin: 0px;
}

.comment-interaction-links li {
    display: inline;
    padding-right: 0px;
}

.comment-interaction-links li:before {
    content: "(";
}

.comment-interaction-links li:after {
    content: ")";
}

.comment .header .inner {
    padding: 5px;
}

.comment .controls {
    float: right;
    text-align: right;
}

.comment {
    margin-bottom: 8px;
}

.comment .header .left {
    float: left;
    padding-right: 5px;
}

.comment .header .right {
    float: right;
    text-align: right;
    padding-left: 5px;
}

.comment .userpic {
    float: left;
    padding-right: 5px;
}

.clear {
    clear: both;
}

.anonymous {
    font-style: italic;
}

.comment-from-text {
    display: none;
}

.comment-date-text {
    display: none;
}

.comment .contents {
    margin-top: 10px;
    margin-bottom: 10px;
}

.entry-poster-info {
    float: right;
    text-align: right;
    padding: 10px;
    max-width: 250px;
}

.no-userpic .userpic {
    padding-right: auto;
    min-width: 100px;
    min-height: 100px;
    /* background-image: url(http://www.dreamwidth.org/img/profile_icons/user.png); */
    background-image: url(http://www.dreamwidth.org/img/nouserpic.png);
    background-position: top right;
    background-repeat: no-repeat;
    margin-right: 10px;
}

.full .comment-title {
    margin: 0px;
}

.full .comment-timestamp, .full .comment-poster {
    display: block;
}

.partial .comment-title {
    font-weight: normal;
    display: inline;
}

.partial .comment-timestamp, .partial .comment-poster {
    display: inline;
}

.entry .contents {
    overflow: hidden;
}

.comment .header {
    overflow: hidden;
}

.userlite-interaction-links {
    padding: 0px;
    margin: 0px;
}

.userlite-interaction-links li {
    display: inline;
}

#archive-month .entry-title {
    padding: 0px;
    margin: 0px;
}

#archive-month br {
    display: none;
}

.entry .tag {
    margin-top: 10px;
}

.tag ul {
    padding: 0px;
    margin: 0px;
    display: inline;
}

.tag li {
    display: inline;
}

.tag li:before {
    content: "#";
}

.module:first-child {
    margin-top: 0px;
}

.module {
    margin-top: 10px;
}

.edittime {
    margin-top: 1em;
}

""";
}

###############################################################################################
# CHANGE DEFAULT VALUES
###############################################################################################

set font_base = "Verdana";
set font_fallback = "sans-serif";
set font_base_size = "13";
set font_base_units = "px";

set font_comment_title = "Arial";
set font_comment_title_size = "18";
set font_comment_title_units = "px";

set font_comment_control = "Verdana";
set font_comment_control_size = "10";
set font_comment_control_units = "px";

set color_page_link = "#0000CC";
set color_page_link_visited = "#330066";

set module_layout_sections = "none|(none)|head|Header|foot|Footer|sidebar1|First Sidebar|sidebar2|Second Sidebar";

set module_navlinks_section = "head";
set module_userprofile_section = "sidebar1";
set module_pagesummary_section = "foot";
set module_tags_section = "sidebar2";
set module_links_section = "sidebar2";
set module_syndicate_section = "foot";
set module_calendar_section = "sidebar1";
set module_poweredby_section = "foot";
set module_time_section = "foot";
set module_customtext_section = "sidebar1";
set module_active_section = "none";
set module_credit_section = "foot";
set module_search_section = "none";
set module_cuttagcontrols_section = "none";

###############################################################################################
# CUSTOMIZATION OPTIONS
###############################################################################################

propgroup spoilers = "Spoilers";

propgroup spoilers {
    property use spoiler_fix_colors_comment;
    property use spoiler_fix_colors_text;
    property use spoiler_reset_colors_text;

    property use spoiler_black_on_black;
    property use spoiler_white_text;

    property use spoiler_special_tag_use;
    property use spoiler_special_tag_name;

    property use spoiler_cut_text_closed;
    property use spoiler_cut_text_open;
    property use spoiler_cut_show_open;

    property use spoiler_cut_entries;

    property use spoiler_fallback_color;    
    property use spoiler_hard_links;
    property use spoiler_hard_open_all;
    property use spoiler_show_checkboxes;
}

propgroup layout = "Layout";

propgroup layout {
    property use layout_sidebar;
    property use layout_sidebar_width_units;
    property use layout_sidebar_width_first;
    property use layout_sidebar_width_second;
    property use layout_header_show;
    property use layout_header_vertical;
    property use layout_footer_show;
    property use layout_footer_vertical;
}

propgroup decorations = "Decorations";

propgroup decorations {
    property use decoration_marked_header;
    property use decoration_marked_footer;
    property use decoration_marked_sidebars;
    property use decoration_marked_body;
    property use decoration_marked_modules_header;
    property use decoration_marked_modules_sidebar;
    property use decoration_marked_modules_footer;
    property use decoration_border_thickness;
    property use decoration_border_style;
    property use decoration_border_color;
    property use decoration_border_radius;
    property use decoration_shadow_show;
    property use decoration_shadow_horizontal;
    property use decoration_shadow_vertical;
    property use decoration_shadow_blur;
    property use decoration_shadow_spread;
    property use decoration_shadow_color;
    property use decoration_shadow_inset;

    property use decoration_box_margin;
    property use decoration_box_padding;
}

propgroup background = "Background";

propgroup background {
    property use color_page_background;
    property use image_background_page_group;

    property use color_module_background;
    property use image_background_module_group;

    property use color_header_background;
    property use image_background_header_group;

    property use color_footer_background;
    property use image_background_header_height;

    property use color_entry_background;
    property use image_background_entry_group;

    property use color_background_sidebar1;
    property use image_background_sidebar1_group;

    property use color_background_sidebar2;
    property use image_background_sidebar2_group;

    property use color_comment_header1;
    property use image_comment_header1_group;

    property use color_comment_header2;
    property use image_comment_header2_group;

    property use color_comment_header_alternate;
    property use color_comment_header_depth;

}

propgroup colors = "Text Colors";

propgroup colors {
    property use color_page_text;
    property use color_page_link;
    property use color_page_link_active;
    property use color_page_link_hover;
    property use color_page_link_visited;

    property use color_module_text;
    property use color_module_link;
    property use color_module_link_active;
    property use color_module_link_hover;
    property use color_module_link_visited;
    property use color_module_title;

    property use color_page_title;

    property use color_footer_link;
    property use color_footer_link_active;
    property use color_footer_link_hover;
    property use color_footer_link_visited;

    property use color_entry_text;
    property use color_entry_link;
    property use color_entry_link_active;
    property use color_entry_link_hover;
    property use color_entry_link_visited;
    property use color_entry_title;
    property use color_entry_interaction_links;
    property use color_entry_interaction_links_active;
    property use color_entry_interaction_links_hover;
    property use color_entry_interaction_links_visited;

    property use color_comment_title;
}

propgroup presentation {
    property use num_items_recent;
    property use num_items_reading;
    property use use_custom_friend_colors;
    property use use_shared_pic;
    property use use_journalstyle_entry_page;
    property use margins_size;
    property use margins_unit;
    property use custom_control_strip_colors;

    property use reverse_sortorder_group;
    property use reg_firstdayofweek;
    property use tags_page_type;
    property use num_items_icons;
    property use icons_page_sort;

    property use all_entrysubjects;
    property use entry_datetime_format_group;
    property use comment_datetime_format_group;
    property use userpics_style_group;
    property use userpics_position;
    property use entry_metadata_position;
    property use userlite_interaction_links;
    property use entry_management_links;
}

propgroup fonts {
    property use font_base;
    property use font_fallback;
    property use font_base_size;
    property use font_base_units;
    property use font_module_heading;
    property use font_module_heading_size;
    property use font_module_heading_units;
    property use font_module_text;
    property use font_module_text_size;
    property use font_module_text_units;
    property use font_journal_title;
    property use font_journal_title_size;
    property use font_journal_title_units;
    property use font_journal_subtitle;
    property use font_journal_subtitle_size;
    property use font_journal_subtitle_units;
    property use font_entry_title;
    property use font_entry_title_size;
    property use font_entry_title_units;
    property use font_comment_title;
    property use font_comment_title_size;
    property use font_comment_title_units;
    property use font_comment_control;
    property use font_comment_control_size;
    property use font_comment_control_units;

    property use font_sources;
}

propgroup text {
    property use text_module_userprofile;
    property use text_module_links;
    property use text_module_syndicate;
    property use text_module_tags;
    property use text_module_popular_tags;
    property use text_module_pagesummary;
    property use text_module_active_entries;
    property use text_module_customtext;
    property use text_module_customtext_url;
    property use text_module_customtext_content;
    property use text_module_credit;
    property use text_module_search;
    property use text_module_cuttagcontrols;
    property use text_module_subscriptionfilters;

    property use text_view_recent;
    property use text_view_archive;
    property use text_view_friends;
    property use text_view_friends_comm;
    property use text_view_network;
    property use text_view_tags;
    property use text_view_memories;
    property use text_view_userinfo;

    property use text_entry_prev;
    property use text_entry_next;
    property use text_edit_entry;
    property use text_edit_tags;
    property use text_mem_add;
    property use text_tell_friend;
    property use text_watch_comments;
    property use text_unwatch_comments;

    property use text_read_comments;
    property use text_read_comments_friends;
    property use text_read_comments_screened_visible;
    property use text_read_comments_screened;
    property use text_post_comment;
    property use text_post_comment_friends;
    property use text_permalink;

    property use text_meta_location;
    property use text_meta_mood;
    property use text_meta_music;
    property use text_meta_xpost;
    property use text_tags;

    property use text_stickyentry_subject;

    property use text_max_comments;
    property use text_skiplinks_back;
    property use text_skiplinks_forward;
}

propgroup modules {
    property use module_userprofile_group;
    property use module_navlinks_group;
    property use module_calendar_group;
    property use module_links_group;
    property use module_syndicate_group;
    property use module_tags_group;
    property use module_pagesummary_group;
    property use module_active_group;
    property use module_time_group;
    property use module_poweredby_group;
    property use module_customtext_group;
    property use module_credit_group;
    property use module_search_group;
    property use module_cuttagcontrols_group;
    property use module_subscriptionfilters_group;
}

propgroup comment {
    property use comment_userpic_group;
    property use comment_subject_group;
    property use comment_author_group;
    property use comment_date_group;
    property use comment_actions_group;
    property use comment_links_group;
    property use comment_metadata_group;
    property use comment_emoticon_group;
    property use comment_select_group;
    property use comment_reply_group;
    property use comment_posted_group;
    property use comment_fix1_group;
    property use comment_fix2_group;
}

propgroup customcss {
    property use external_stylesheet;
    property use include_default_stylesheet;
    property use linked_stylesheet;
    property use custom_css;
}

