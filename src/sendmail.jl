
abstract type MyMail end

@kwdef struct PureTextMail <: MyMail
    subject
    message
end

"""
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




struct Secrets
    sender
    sender_key
end

function Secrets(d::Dict; sender="sender", sender_key="sender_key")
    Secrets(
        d[sender],
        d[sender_key]
    )
end

Secrets(s::Secrets) = s

function SMTPClient.send(MM::MyMail, recipients::Vector{<:AbstractString}, secrets, config::Configuration; test=false, kwargs...)
    sec = Secrets(secrets)

    opt = SendOptions(
        isSSL=config.isSSL,
        username=sec.sender,
        passwd=sec.sender_key,
    )

    if test
        rcpt = to = ["<$(sec.sender)>"] # send to the sender itself when test.
        kwargs = []
    else
        rcpt = to = ["<$(strip(recipient))>" for recipient in recipients]
    end

    from = "<$(sec.sender)>"
    subject = MM.subject
    message = MM.message
    url = config.url

    body = get_body(to, from, subject, message; kwargs...)
    resp = send(url, rcpt, from, body, opt)
end
