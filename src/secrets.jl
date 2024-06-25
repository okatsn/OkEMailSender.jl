"""
`Secrets(sender, sender_key)` construct the `Secrets` structure.

```
struct Secrets
    sender
    sender_key
end
```

"""
struct Secrets
    sender
    sender_key
end


```
`Secrets(d::Dict; sender="sender", sender_key="sender_key")` convert a dictionary to the `Secrets` structure.
```
function Secrets(d::Dict; sender="sender", sender_key="sender_key")
    Secrets(
        d[sender],
        d[sender_key]
    )
end

Secrets(s::Secrets) = s
