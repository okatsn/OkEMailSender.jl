abstract type Configuration end

@kwdef struct DefaultConfiguration <: Configuration
    url = "smtps://smtp.gmail.com:465"
    isSSL = true # `SendOptions` of SMTPClient
end
