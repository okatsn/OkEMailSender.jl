
abstract type MyMail end

@kwdef struct PureTextMail <: MyMail
    text
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

function SMTPClient.send(MM::MyMail, recipients::Vector{<:AbstractString}, secrets, config::Configuration; test=false)
    sec = Secrets(secrets)

    opt = SendOptions(
        isSSL=config.isSSL,
        username=sec.sender,
        passwd=sec.sender_key,
    )

    if test
        rcpt = ["<$(sec.sender)>"] # send to the sender itself when test.
    else
        rcpt = ["<$(strip(recipient))>" for recipient in recipients]
    end
    resp = send(url, rcpt, from, body, opt)
end
