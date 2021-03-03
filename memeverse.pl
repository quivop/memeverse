layerinfo "type" = "theme";
layerinfo "name" = "Memeverse";
layerinfo "is_public" = 1;
layerinfo "source_viewable" = 1;
layerinfo "majorversion" = 0;
layerinfo "minorversion" = 1;

###############################################################################################
#  __  __                                               _____ _                         
# |  \/  | ___ _ __ ___   _____   _____ _ __ ___  ___  |_   _| |__   ___ _ __ ___   ___ 
# | |\/| |/ _ \ '_ ` _ \ / _ \ \ / / _ \ '__/ __|/ _ \   | | | '_ \ / _ \ '_ ` _ \ / _ \
# | |  | |  __/ | | | | |  __/\ V /  __/ |  \__ \  __/   | | | | | |  __/ | | | | |  __/
# |_|  |_|\___|_| |_| |_|\___| \_/ \___|_|  |___/\___|   |_| |_| |_|\___|_| |_| |_|\___|
#                                                                                       
# vvv Based *heavily* on "Spoil Those Comments" by @brsw, browseable here vvv
# ----->  https://www.dreamwidth.org/customize/advanced/layerbrowse?id=622248
#
###############################################################################################


##===============================
## Property setup
##===============================

propgroup colors {
    property Color color_comment_border { des = "Comment border"; }
    property Color color_comment_border_alt { des = "Alternate comment border"; }
    property Color color_comment_background { des = "Comment background"; }
    property Color color_comment_background_alt { des = "Alternate comment background"; }
}

##===============================
## Comment background bs
##===============================

set color_comment_border = "#739adf";
set color_comment_background = "#bbddff";

set color_comment_border_alt = "#eee";
set color_comment_background_alt = "#aaccee";


function print_stylesheet () {

"""
/* Theme CSS */

    .comment-depth-odd > .dwexpcomment .header {
        border: solid 1px $*color_comment_border;
        background-color: $*color_comment_background;
    }
    .comment-depth-even > .dwexpcomment .header {
        border: solid 1px $*color_comment_border_alt;
        background-color: $*color_comment_background_alt;
    }


""";
}

function Page::print_custom_head() {
    """<meta name="viewport" content="width=device-width, initial-scale=1.0">""";
}
