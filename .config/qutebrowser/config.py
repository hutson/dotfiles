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
        "https://ublockorigin.github.io/uAssets/filters/resource-abuse.txt"
])
