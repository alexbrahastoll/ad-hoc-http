# AdHocHTTP

A very simple HTTP client (and definitely not production ready!) implemented to
highlight the differences between blocking and non-blocking GET requests.

It exposes the statuses (`:wait_readable` or `wait_writable`) of a socket when
the non-blocking methods are used.

It is then possible to manually handle them (for example, by using multiple
fibers and switching between them as each socket gets into an waiting state).

## Acknowledgments

This simple client was heavily based on [HTTPray](https://github.com/gworley3/httpray).
