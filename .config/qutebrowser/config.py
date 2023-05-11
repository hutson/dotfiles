# Don't load settings configured through the UI.
config.load_autoconfig(True)

config.set('colors.webpage.darkmode.enabled', True)

# Enable adblocking in Qutebrowser.
config.set('content.blocking.enabled', True)

# Custom list of filter lists that are meant to significantly increase the
# internet resources that are filtered out by Qutebrowser.
# List based on - https://github.com/gorhill/uBlock/blob/master/assets/assets.json
config.set('content.blocking.adblock.lists', [
        "https://ublockorigin.github.io/uAssets/filters/badlists.txt",
        "https://ublockorigin.github.io/uAssets/filters/filters.txt",
        "https://ublockorigin.github.io/uAssets/filters/badware.txt",
        "https://ublockorigin.github.io/uAssets/filters/privacy.txt",
        "https://ublockorigin.github.io/uAssets/filters/resource-abuse.txt",
        "https://ublockorigin.github.io/uAssets/filters/unbreak.txt",
        "https://ublockorigin.github.io/uAssets/filters/quick-fixes.txt",
        "https://filters.adtidy.org/extension/ublock/filters/2_without_easylist.txt",
        "https://filters.adtidy.org/extension/ublock/filters/11.txt",
        "https://ublockorigin.github.io/uAssets/thirdparties/easylist.txt",
        "https://filters.adtidy.org/extension/ublock/filters/17.txt",
        "https://ublockorigin.github.io/uAssets/filters/lan-block.txt",
        "https://ublockorigin.github.io/uAssets/thirdparties/easyprivacy.txt",
        "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-online.txt",
        "https://malware-filter.gitlab.io/malware-filter/phishing-filter.txt",
        "https://malware-filter.gitlab.io/malware-filter/pup-filter.txt",
        "https://filters.adtidy.org/extension/ublock/filters/14.txt",
        "https://filters.adtidy.org/extension/ublock/filters/4.txt",
        "https://secure.fanboy.co.nz/fanboy-antifacebook.txt",
        "https://secure.fanboy.co.nz/fanboy-annoyance_ubo.txt",
        "https://secure.fanboy.co.nz/fanboy-cookiemonster_ubo.txt",
        "https://easylist.to/easylist/fanboy-social.txt",
        "https://ublockorigin.github.io/uAssets/filters/annoyances.txt",
        "https://someonewhocares.org/hosts/hosts",
        "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext",
        "https://raw.githubusercontent.com/AnXh3L0/blocklist/master/albanian-easylist-addition/Albania.txt",
        "https://easylist-downloads.adblockplus.org/Liste_AR.txt",
        "https://stanev.org/abp/adblock_bg.txt",
        "https://filters.adtidy.org/extension/ublock/filters/224.txt",
        "https://raw.githubusercontent.com/tomasko126/easylistczechandslovak/master/filters.txt",
        "https://easylist.to/easylistgermany/easylistgermany.txt",
        "https://adblock.ee/list.php",
        "https://raw.githubusercontent.com/finnish-easylist-addition/finnish-easylist-addition/gh-pages/Finland_adb.txt",
        "https://filters.adtidy.org/extension/ublock/filters/16.txt",
        "https://www.void.gr/kargig/void-gr-filters.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/SerboCroatianList.txt",
        "https://raw.githubusercontent.com/hufilter/hufilter/master/hufilter-ublock.txt",
        "https://raw.githubusercontent.com/ABPindo/indonesianadblockrules/master/subscriptions/abpindo.txt",
        "https://easylist-downloads.adblockplus.org/indianlist.txt",
        "https://raw.githubusercontent.com/MasterKia/PersianBlocker/main/PersianBlocker.txt",
        "https://adblock.gardar.net/is.abp.txt",
        "https://raw.githubusercontent.com/easylist/EasyListHebrew/master/EasyListHebrew.txt",
        "https://easylist-downloads.adblockplus.org/easylistitaly.txt",
        "https://filters.adtidy.org/extension/ublock/filters/7.txt",
        "https://cdn.jsdelivr.net/gh/List-KR/List-KR@master/filter-uBlockOrigin.txt",
        "https://raw.githubusercontent.com/EasyList-Lithuania/easylist_lithuania/master/easylistlithuania.txt",
        "https://raw.githubusercontent.com/Latvian-List/adblock-latvian/master/lists/latvian-list.txt",
        "https://raw.githubusercontent.com/DeepSpaceHarbor/Macedonian-adBlock-Filters/master/Filters",
        "https://easydutch-ubo.github.io/EasyDutchCDN/EasyDutch.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/NorwegianList.txt",
        "https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-adblock-filters/adblock.txt",
        "https://raw.githubusercontent.com/olegwukr/polish-privacy-filters/master/anti-adblock.txt",
        "https://road.adblock.ro/lista.txt",
        "https://raw.githubusercontent.com/easylist/ruadlist/master/RuAdList-uBO.txt",
        "https://easylist-downloads.adblockplus.org/easylistspanish.txt",
        "https://filters.adtidy.org/extension/ublock/filters/9.txt",
        "https://raw.githubusercontent.com/betterwebleon/slovenian-list/master/filters.txt",
        "https://raw.githubusercontent.com/lassekongo83/Frellwits-filter-lists/master/Frellwits-Swedish-Filter.txt",
        "https://raw.githubusercontent.com/easylist-thailand/easylist-thailand/master/subscription/easylist-thailand.txt",
        "https://filters.adtidy.org/extension/ublock/filters/13.txt",
        "https://raw.githubusercontent.com/abpvn/abpvn/master/filter/abpvn_ublock.txt"
])
