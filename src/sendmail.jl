
abstract type MyMail end

@kwdef struct PureTextMail <: MyMail
    subject
    message
end


@kwdef struct HTMLMail <: MyMail
    subject
    message
end

"""
`HTMLMail(subject, text::HypertextLiteral.Result)`

# Example

```jldoctest
using HypertextLiteral, OkHypertextTools, OkEMailSender
using DataFrames

df = DataFrame(:Name => ["John", "Doh"], :Income => [100, 200])

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
            <p><h1> Hello </h1></p>

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

# output

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

```
"""
function HTMLMail(subject, text::HypertextLiteral.Result)
    io = IOBuffer()
    print(io, text)
    message = get_mime_msg(HTML(String(take!(io)))) # do this if message is HTML
    HTMLMail(subject, message)
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
