-- Source for the msteams: URL handler app that bootstrap.sh compiles into
-- ~/Applications. A URL scheme handler has to be an app bundle, so this is the
-- thinnest possible one: it forwards the URL to teams-link-open.
on open location this_URL
	do shell script "$HOME/.local/bin/teams-link-open " & quoted form of this_URL
end open location
