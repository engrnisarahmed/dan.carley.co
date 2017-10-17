---
date: 2016-07-05T08:54:52Z
title: Mocking APIs in Go Tests
---

There are two patterns that I've come to really appreciate when testing Go
code that uses libraries to access third-party APIs. They aren't necessarily
specific to Go. I came to Go from Ruby and Python, so this might actually be
an "ode to static typing" in disguise.

## Examples

I'm going to use the [Ginkgo][] / [Gomega][] testing framework in my code
examples, though the same functionality can be achieved using the standard
library and some helper code. I'll also reference two libraries that I've
been using recently:

- [go-github][] for [GitHub][]
- [go.strava][] for [Strava][]

[go-github]: https://github.com/google/go-github
[GitHub]: https://github.com
[go.strava]: https://github.com/strava/go.strava
[Strava]: https://www.strava.com/

[Ginkgo]: https://onsi.github.io/ginkgo
[Gomega]: https://onsi.github.io/gomega

## Patterns

### Injecting mock servers

In Ruby it's possible and commonplace (though not necessarily desirable) to
[monkey-patch][] objects at runtime, which can be used in tests to change
the behaviour of libraries and their underlying dependencies. It can be very
powerful but equally very difficult understand what's going on.

[monkey-patch]: https://en.wikipedia.org/wiki/Monkey_patch

Go doesn't support monkey-patching. In most cases you need to structure your
code in a way that you can use [dependency injection][] (in its simplest
form; no magic frameworks) to pass alternate objects for testing. Sometimes
you may need to use custom [interfaces as test doubles][], but other times
the configuration you need will already be exposed, either for the library's
own tests or other functionality.

[dependency injection]: https://en.wikipedia.org/wiki/Dependency_injection
[interfaces as test doubles]: https://www.google.co.uk/search?q=golang%20interfaces%20testing

We start by creating a new HTTP server where we can make assertions on
requests received and generate our own responses. We need the URL to give to
our client:

```go
var server *ghttp.Server

BeforeEach(func() {
  server = ghttp.NewServer()

  serverURL, err := url.Parse(server.URL())
  Expect(err).ToNot(HaveOccurred())
})
```

Telling `go-github` to use our test server instead of `github.com` requires
very little effort because [`github.Client`][] exposes a public field called
`BaseURL`, which is foremost intended for using the library against GitHub
Enterprise, but is also [used by the library's own tests][github-tests].

We can do the same to point a client at our test server:

[`github.Client`]: https://godoc.org/github.com/google/go-github/github/#Client
[github-tests]: https://github.com/google/go-github/blob/07995e49c22dcb1e372c88ff12793b0194433e1c/github/github_test.go#L43-L47

```go
var client *github.Client

BeforeEach(func() {
  …
  client = github.NewClient(nil)
  client.BaseURL = serverURL
})
```

Telling `go.strava` to use our test server requires a few more lines of
code. Like a lot of HTTP libraries (including `go-github`) it allows you to
pass your own [`http.Client`][] to the client constructor. This is powerful
because it allows you to provide an HTTP client that implements
authentication, or caching, or any other kind of request/response
manipulation. The [library's own tests][strava-tests] do this to provide an
[`http.Transport`][] that returns responses from fixture strings and files.

[`http.Client`]: https://golang.org/pkg/net/http/#Client
[`http.Transport`]: https://golang.org/pkg/net/http/#Transport
[strava-tests]: https://github.com/strava/go.strava/blob/f5c7cee1038b80d25e3d262208d295c10ca2ac4b/service_test.go#L26-L89

We can do something similar to make sure that all requests connect to our
test server:

```go
var client *strava.Client

BeforeEach(func() {
  …
  dialMock := func(network, addr string) (net.Conn, error) {
    return net.Dial(network, serverURL.Host)
  }

  httpClient := &http.Client{
    Transport: &http.Transport{
      Dial:    dialMock,
      DialTLS: dialMock,
    },
  }

  client = strava.NewClient("token", httpClient)
})
```

### Mocking JSON responses

Now that we're getting requests, we need to generate the right responses.
For the APIs that we're dealing with the response bodies are JSON document
strings.

Generating these is made easier by Go's [`encoding/json`][] package which
converts JSON to structs and vice versa. We can use the public structs from
the library instead of handwriting the JSON ourselves, which is more
succinct and benefits from type checking, so you'll get fast feedback if you
misspell a field name or the structure of the API and library change. For
some tests we can also get away with only populating a subset of fields.

[`encoding/json`]: https://golang.org/pkg/encoding/json/

For `go-github` it can look like this:

```go
const org = "acme"
var fixture []github.User

BeforeEach(func() {
  fixture = []github.User{
    {ID: github.Int(1), Login: github.String("one")},
    {ID: github.Int(2), Login: github.String("two")},
    {ID: github.Int(3), Login: github.String("three")},
  }

  server.AppendHandlers(
    ghttp.CombineHandlers(
      ghttp.VerifyRequest("GET", fmt.Sprintf("/orgs/%s/members", org)),
      ghttp.RespondWithJSONEncoded(http.StatusOK, fixture),
    ),
  )
})

It("should return fixture of users", func() {
  opts := &github.ListMembersOptions{}
  result, _, err := client.Organizations.ListMembers(org, opts)
  Expect(err).ToNot(HaveOccurred())
  Expect(result).To(Equal(fixture))
})
```

For `go.strava` it can look like this:

```go
var fixture []*strava.ActivitySummary

BeforeEach(func() {
  now := time.Now()
  athlete := strava.AthleteSummary{CreatedAt: now, UpdatedAt: now}

  fixture = []*strava.ActivitySummary{
    {Id: 1, Name: "one", Athlete: athlete, StartDate: now, StartDateLocal: now},
    {Id: 2, Name: "two", Athlete: athlete, StartDate: now, StartDateLocal: now},
    {Id: 3, Name: "three", Athlete: athlete, StartDate: now, StartDateLocal: now},
  }

  server.AppendHandlers(
    ghttp.CombineHandlers(
      ghttp.VerifyRequest("GET", "/api/v3/athlete/activities"),
      ghttp.RespondWithJSONEncoded(http.StatusOK, fixture),
    ),
  )
})

It("should return fixture of activities", func() {
  result, err := strava.NewCurrentAthleteService(client).ListActivities().Do()
  Expect(err).ToNot(HaveOccurred())
  Expect(result).To(Equal(fixture))
})
```

The above examples are simplistic because they're testing behaviour that should
be covered by the library's own tests. This comes in more useful when
testing your own code that wraps the library to perform error handling or
pagination. For example:

```go
func PaginationHeader(url string, next int) http.Header {
  headers := http.Header{}
  headers.Set("Link", fmt.Sprintf(`<%s?page=%d>; rel="next"`, url, next))

  return headers
}

BeforeEach(func() {
  server.AppendHandlers(
    ghttp.CombineHandlers(
      ghttp.VerifyRequest("GET", path),
      ghttp.RespondWithJSONEncoded(http.StatusOK, fixture[0:2],
        PaginationHeader(server.URL()+path, 1)),
    ),
    ghttp.CombineHandlers(
      ghttp.VerifyRequest("GET", path),
      ghttp.RespondWithJSONEncoded(http.StatusOK, fixture[2:],
        PaginationHeader(server.URL()+path, 0)),
    ),
  )
})

It("should return fixture of users", func() {
  result, err := GetMembersAllPages(client, org)
  Expect(err).ToNot(HaveOccurred())
  Expect(result).To(Equal(fixture))
})
```

## Problems

### time.Time

The last `go.strava` example contains quite a lot of additional fields in
the fixture. These are required in order to compare the fixture and result,
because marshalling and unmarshalling a zero [`time.Time`][] object does not
produce something that has `==` equality. An alternative to populating the
fields manually could be to use an intermediate function or [custom
matcher][] to convert or ignore those fields.

[`time.Time`]: https://golang.org/pkg/time/#Time
[custom matcher]: https://onsi.github.io/gomega/#adding-your-own-matchers
[time.Time issue]: https://github.com/golang/go/issues/10089

### json.RawMessage

The other problem that I've encountered is structs that use
[`*json.RawMessage`][] to delay the unmarshalling of some fields. They are
used by [`github.Event`][] because the payload is one of many types, such as
[`github.PushEvent`][]. This is troublesome for writing tests that use
slices and refer to both the inner and outer objects because it requires
more than one operation to construct or reference each one.

[`*json.RawMessage`]: https://golang.org/pkg/encoding/json/#RawMessage
[`github.Event`]: https://godoc.org/github.com/google/go-github/github/#Event
[`github.PushEvent`]: https://godoc.org/github.com/google/go-github/github/#PushEvent

Constructing one of these objects now requires several operations:

```go
event := &github.Event{
  ID:   github.String("201"),
  Type: github.String("PushEvent"),
}
payload := &github.PushEvent{
  PushID: github.Int(101),
  Ref:    github.String("aaaaaaa"),
}

payloadJSON, err := json.Marshal(payload)
Expect(err).ToNot(HaveOccurred())

payloadRaw := json.RawMessage(payloadJSON)
event.RawPayload = &payloadRaw
```

Accessing the original payload now requires an additional type assertion:

```go
pushEvent, ok := event.Payload().(*github.PushEvent)
Expect(ok).To(BeTrue())
Expect(pushEvent).To(Equal(payload))
```

We can cheat by defining a new struct that [embeds][] the two types that we
need in a way that when marshalled it produces the equivalent `github.Event`
JSON:

[embeds]: https://golang.org/doc/effective_go.html#embedding

```go
type EventFixture struct {
  *github.Event
  RawPayload *github.PushEvent `json:"payload,omitempty"`
}
```

Then we can write a test for a function which only fetches the
`github.PushEvent` objects like this:

```go
var pushEventFixture []*github.PushEvent

BeforeEach(func() {
  pushEventFixture = []*github.PushEvent{
    {
      PushID: github.Int(101),
      Ref: github.String("aaaaaaa"),
    }, {
      PushID: github.Int(102),
      Ref: github.String("bbbbbbb"),
    },
  }

  eventFixture := []*EventFixture{
    {
      Event: &github.Event{ID: github.String("201"), Type: github.String("PushEvent")},
      RawPayload: pushEventFixture[0],
    }, {
      Event: &github.Event{ID: github.String("202"), Type: github.String("PushEvent")},
      RawPayload: pushEventFixture[1],
    },
  }

  server.AppendHandlers(
    ghttp.CombineHandlers(
      ghttp.VerifyRequest("GET", path),
      ghttp.RespondWithJSONEncoded(http.StatusOK, eventFixture),
    ),
  )
})

It("should return fixture of pushevents", func() {
  result, err := GetPushEvents(client, user)
  Expect(err).ToNot(HaveOccurred())
  Expect(result).To(Equal(pushEventFixture))
})
```
