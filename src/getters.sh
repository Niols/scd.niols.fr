#!/bin/sh

if ! command -v jq >/dev/null; then
    printf >&2 'jq is required\n'
    exit 2
fi

################################################################################
##    ___         _           _
##   / __|___ _ _| |_ _____ _| |_
##  | (__/ _ \ ' \  _/ -_) \ /  _|
##   \___\___/_||_\__\___/_\_\\__|
##
##  The context in which we are considering the objects. This is a JSON object
##  of three fields:
##
##  - `current` contains the current JSON object being considered. There might
##    not be any, for instance if we are at the beginning of an iteration.
##
##  - `next` is a JSON array containing the next objects to consider in an
##    iteration. This field only makes sense when iterating and is empty the
##    rest of the time.
##
##  - `parent` contains another context, the parent context. This allows to go
##    back after an iteration, for instance. If there is no parent, `parent` is
##    `null.`

CONTEXT=$(jq -n '{current:null, next:[], parents:null}')

## Tiny helper to die while printing the context.
##
die () {
    printf >&2 "$@"
    printf >&2 '\nContext:\n  %s\n\n' "$CONTEXT"
}

## `get` selects the current object, if there is one, or dies otherwise.
##
get () {
    _get=$(echo "$CONTEXT" | jq '.current')
    [ "$_get" != null ] && echo "$_get" || die 'There is no current object.'
}

## `next` replaces the current object by the first object in the `next` array.
## If the `next` array is empty, then the parent context is restored and `next`
## returns `1`. If there is no parent context to restore, `next` dies.
##
next () {
    if [ "$(echo "$CONTEXT" | jq '.next != []')" = true ]; then
        ## If the `next` array is not empty, then we take its first element as
        ## the new current object.
        CONTEXT=$(echo "$CONTEXT" | jq '{current:.next[0], next:.next[1:], parent:.parent}')
        return 0
    elif [ "$(echo "$CONTEXT" | jq '.parent != null')" = true ]; then
        ## Otherwise, if there is a parent context, then we restore it and
        ## return `1`.
        CONTEXT=$(echo "$CONTEXT" | jq '.parent')
        return 1
    else
        ## Otherwise, we die.
        die 'There is no next but also no parent.'
    fi
}

## `iter` gets into a field of the current object and uses it as `next`
## elements. The current object is pushed as a parent object and there is no
## current object yet (until a use of `next`).
##
iter () {
    _get=$(get | jq ".[\"$1\"]")
    [ "$_get" = null ] && die 'Cannot iter through non-existing field `%s`.' "$1"
    CONTEXT=$(echo "$CONTEXT" | jq '{current:null, next:$next, parent:.}' --argjson next "$_get")
}

################################################################################
##    ___     _   _
##   / __|___| |_| |_ ___ _ _ ___
##  | (_ / -_)  _|  _/ -_) '_(_-<
##   \___\___|\__|\__\___|_| /__/
##

## Normal fields are fields in the current object. `get_field` allows to get
## them in a simple call to `jq`. `exists_field` checks `jq`'s output to deduce
## that the field indeed exists.
##
get_field () {
    get | jq -r ".[\"$1\"]" ## `-r` for raw strings
}
exists_field () {
    _get=$(get_field "$1") && [ "$_get" != null ]
}

## Fancy fields are simply functions. They allow to write helpers like “if this
## field exists, then take it; otherwise take that other one”.
##
exists_fancy_field () { command -v "$1" >/dev/null; }
get_fancy_field () { "$1"; }

## `exists` tests whether the field exists, fancy or not.
##
exists () {
    exists_field "$1" || exists_fancy_field "$1"
}

## `raw` returns the field, fancy or not. The field is returned as-is, without
## any post-treatement.
##
raw () {
    if exists_fancy_field "$1"; then
        get_fancy_field "$1"
    elif exists_field "$1"; then
        get_field "$1"
    else
        die 'no such field: `%s`' "$1"
    fi
}

## `html` returns the field, sanitized for use in HTML. This should basically be
## the default. `raw` should only be used when one knows exactly what they are
## doing.
##
## FIXME: currently, this does nothing.
##
html () {
    raw "$@"
}

## `url` returns the field, sanitized for use in a URL. This should basically be
## the default. `raw` should only be used when one knows exactly what they are
## doing.
##
## FIXME: currently, this does nothing.
##
url () {
    raw "$@"
}

################################################################################
##   ___
##  | __|_ _ _ _  __ _  _
##  | _/ _` | ' \/ _| || |
##  |_|\__,_|_||_\__|\_, |
##                   |__/
##  Some pre-defined fancy fields that we use everywhere.

short_author_or_author () {
    exists short-author && raw short-author || raw author;
}

################################################################################
## Load context from first argument.

CONTEXT=$(jq -n '{current:$current, next:[], parent:null}' --argjson current "$(cat "$1")")
