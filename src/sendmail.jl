
abstract type MyMail end
# The interface that all `MM<:MyMail` should have "subject" and "message".


"""
`PureTextMail(subject, message)`

# Example

```jldoctest
using SMTPClient, OkEMailSender
subject = "Julia logo"
message = "Check out this cool logo!"
attachments = ["julia_logo_color.png"]

PureTextMail(subject, message).message == SMTPClient.get_mime_msg(message)

# output
true
```
"""
struct PureTextMail <: MyMail
    subject
    message
    function PureTextMail(subject, message)
        new(subject, get_mime_msg(message))
    end
end

"""
`HTMLMail(subject, htmltext)`

# Example

```jldoctest
using SMTPClient, OkEMailSender

subject = "A simple HTML test"
message =
    html\"\"\"<h2>An important link to look at!</h2>
    Here's an <a href="https://github.com/aviks/SMTPClient.jl">important link</a>
    \"\"\"

HTMLMail("whatever", message).message == SMTPClient.get_mime_msg(message)

# output

true

```

or simply


```jldoctest
using SMTPClient, OkEMailSender

subject = "A simple HTML test"
message = \"\"\"
    <h2>An important link to look at!</h2>
    Here's an <a href="https://github.com/aviks/SMTPClient.jl">important link</a>
    \"\"\"

HTMLMail("whatever", message).message == SMTPClient.get_mime_msg(HTML(message))

# output

true

```



`HTMLMail(subject, text::HypertextLiteral.Result)`

# Example

```jldoctest
using HypertextLiteral, OkHypertextTools, OkEMailSender
using DataFrames

df = DataFrame(:Name => ["John", "Doh"], :Income => [100, 200])

subject = "Hello"

msg0 = @htl(\"\"\"
<html>
    <head>
        <style>
        h1 {
            font-size: 24px;
            font-weight: bold;
        }

        h2 {
            font-size: 18px;
            font-weight: bold;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        table, th, td {
            border: 1px solid black;
        }
        </style>
    </head>

    <body>

        <p>
            <p><h1> \$subject </h1></p>

            <p>This is a table: \$(OkHypertextTools.render_table(df))</p>

            <p>
                This is a list
                <ul>
                    <li>item 1</li>
                    <li>item 2</li>
                </ul>
            </p>
        </p>
    </body>
</html>
\"\"\")

HTMLMail(subject, msg0).message |> print

# output

Content-Type: text/html;
Content-Transfer-Encoding: 7bit;


<html>
<body><html>
    <head>
        <style>
        h1 {
            font-size: 24px;
            font-weight: bold;
        }

        h2 {
            font-size: 18px;
            font-weight: bold;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        table, th, td {
            border: 1px solid black;
        }
        </style>
    </head>

    <body>

        <p>
            <p><h1> Hello </h1></p>

            <p>This is a table: <table><caption><h3> </h3></caption>
<thead><tr><th>Name<th>Income<tbody>
<tr><td>John<td>100
<tr><td>Doh<td>200
</tbody></table></p>

            <p>
                This is a list
                <ul>
                    <li>item 1</li>
                    <li>item 2</li>
                </ul>
            </p>
        </p>
    </body>
</html>
</body>
</html>

```
"""
struct HTMLMail <: MyMail
    subject
    message
    function HTMLMail(subject, message)
        message = my_get_mine_msg(message)
        new(subject, message)
    end
end

my_get_mine_msg(str::String) = get_mime_msg(HTML(str))
my_get_mine_msg(str::HTML) = get_mime_msg(str)

# since `get_mime_msg(str)` returns `String`, infinitely recursive fallback occurs if you use `HTMLMail(..., ::String)` and `HTMLMail(..., ::HTML)` to dispatch.
function my_get_mine_msg(text::HypertextLiteral.Result)
    io = IOBuffer()
    print(io, text)
    get_mime_msg(HTML(String(take!(io)))) # do this if message is HTML
end



"""
`SMTPClient.send(MM::MyMail, recipients::Vector{<:AbstractString}, secrets, config::Configuration; test=true, kwargs...)` send `MyMail` to `recipients` with `OkEMailSender.Secrets` and `OkEMailSender.Configuration`.

It supports `kwargs` for `SMTPClient.get_body`.


# Example

```
using OkEMailSender
send(
    PureTextMail("title", "Hello, how are you?"),
    ["me@test.com", "foo@test.com"],
    Dict("sender" => "foobar@gmail.com", "sender_key" => "a5s8 6ae8 a6w4 hy5e"),
    OkEMailSender.DefaultConfiguration();
    cc = ["hello@test.com", "world@test.com"],
    replyto = "you@gmail.com",
    attachments=["img/publicTransport.png", "img/map.jpg"]
    )
```

Noted that the major difference is that there is no need for brackets (e.g., `["<me@test.com>", "<foo@test.com>"]`) when using `OkEMailSender.send`, comparing to `SMTPClient.send`.
"""
function OkEMailSender.send(MM::MyMail, recipients::Vector{<:AbstractString}, secrets, config::Configuration; test=true, kwargs...)
    sec = Secrets(secrets)

    opt = SendOptions(
        isSSL=config.isSSL,
        username=sec.sender,
        passwd=sec.sender_key,
    )

    recipients = address_cleaner(recipients)
    ccs = get(kwargs, :cc, String[]) |> address_cleaner
    replyto0 = get(kwargs, :replyto, "") |> address_cleaner |> only
    noreplyto = isempty(replyto0)


    if test
        recipients = recipients .* ".test"
        ccs = ccs .* ".test"

        if !noreplyto
            replyto0 * ".test"
        end
    end


    rcpt = to = ["<$(recipient)>" for recipient in recipients]

    cc = ["<$(c)>" for c in ccs]
    replyto = ifelse(noreplyto, "", "<$(replyto0)>")



    from = "<$(sec.sender)>"
    subject = MM.subject
    message = MM.message
    url = config.url

    body = get_body(to, from, subject, message; kwargs..., cc, replyto)
    # previous kwargs will be override, see https://docs.julialang.org/en/v1/manual/functions/#Keyword-Arguments
    resp = send(url, rcpt, from, body, opt)
end

"""
OkEMailSender.send(MM::MyMail, recipients::Vector{<:AbstractString}, secrets; kwargs...) = send(MM, recipients, secrets, DefaultConfiguration(); kwargs...)
"""
OkEMailSender.send(MM::MyMail, recipients::Vector{<:AbstractString}, secrets; kwargs...) = send(MM, recipients, secrets, DefaultConfiguration(); kwargs...)


function address_cleaner(str::AbstractString)
    addresses = split(str, ";") .|> strip
    filter!(!isempty, addresses)
    return addresses
end

function address_cleaner(strvec::Vector{<:AbstractString})
    addresses = strvec .|> strip
    return addresses
end
