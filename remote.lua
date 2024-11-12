-- Local Variables
local host;
local port;
local access_token;
local tid = -1;

-- Events

events.focus = function()
    -- start some timers...
    host = settings.host;
    port = settings.port;
    auth();
end

events.blur = function()
    -- stop some timers...
end

events.destroy = function()
    -- unload some resources...
end

-- Web Request

function auth()
    local url = "http://" .. host .. ":" .. port .. "/auth/unified-remote";
    local headers = { ["accept"] = "application/json" };

    local req = {
        method = "post",
        url = url,
        mime = "application/json",
        headers = headers,
        content = ""
    };

    libs.http.request(req, function(err, resp)
        if (err or resp == nil or resp.status ~= 200) then
            libs.server.update({
                type = "dialog",
                title = "Youtube Music Connection",
                text = "A connection to Youtube Music could not be established.\n\n" ..
                    "Please check that you are using the correct host and port in unified remote settings.\n" ..
                    "Also, check if the API server setting in the Youtube Music app is enabled.",
                children = { { type = "button", text = "OK" } }
            });
            return false;
        else
            access_token = libs.data.fromjson(resp.content).accessToken;
        end
    end);
end

function request(url, data)
    if (access_token == nil) then
        auth();
    end
    local req = {
        method = "post",
        url = url,
        headers = {
            ["Authorization"] = "Bearer " .. access_token,
            ["accept"] = "application/json"
        },
        mime = "application/json",
        content = data
    }
    local ok, resp = pcall(libs.http.request, req);
    if (ok and resp.status == 200) then
        return resp;
    else
        libs.server.update({ id = "title", text = "[Not Connected]" });
        return nil;
    end
end

function send(cmd, key, val)
    local url = "http://" .. host .. ":" .. port .. "/api/v1/";
    local data;
    if (cmd ~= nil) then
        url = url .. cmd;
    end
    if (key ~= nil) and (val ~= nil) then
        data = libs.data.tojson({ [key] = val });
    end
    return request(url, data);
end

-- Actions

actions.playpause = function()
    send("toggle-play");
end
actions.previous = function()
    send("previous");
end
actions.next = function()
    send("next");
end
actions.like = function()
    send("like");
end
actions.dislike = function()
    send("dislike");
end
actions.mute = function()
    send("toggle-mute");
end
actions.volume_change = function(vol)
    send("volume", "volume", vol);
end
