-- Local Variables
local host;
local port;
local accessToken;
local tid = -1;

-- Events

events.focus = function()
    -- start some timers...
    host = settings.host;
    port = settings.port;
    accessToken = settings.accessToken;
    if (accessToken == nil) or (accessToken == "") then
        auth();
    end
    update_info();
end

events.blur = function()
    -- stop some timers...
    libs.timer.cancel(tid);
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
                children = {
                    { type = "button", text = "OK" }
                }
            });
            libs.server.update({ id = "authorize", visibility = "visible" });
            return false;
        else
            accessToken = libs.data.fromjson(resp.content).accessToken;
            settings.accessToken = accessToken;
            libs.server.update({ id = "authorize", visibility = "gone" });
            return true;
        end
    end);
end

function request(url, data, method)
    if (method == nil) then
        method = "post";
    end
    local req = {
        method = method,
        url = url,
        headers = {
            ["Authorization"] = "Bearer " .. accessToken,
            ["accept"] = "application/json"
        },
        mime = "application/json",
        content = data
    }
    local resp = libs.http.request(req);
    if (resp.status == 200 or resp.status == 204) then
        libs.server.update({ id = "authorize", visibility = "gone" });
        return resp;
    else
        libs.server.update({ id = "title", text = "[Not Connected]" });
        libs.server.update({ id = "authorize", visibility = "visible" });
        return nil;
    end
end

function send(cmd, key, val, method)
    local url = "http://" .. host .. ":" .. port .. "/api/v1/";
    local data;
    if (cmd ~= nil) then
        url = url .. cmd;
    end
    if (key ~= nil) and (val ~= nil) then
        data = libs.data.tojson({ [key] = val });
    end
    local resp = request(url, data, method);
    return resp;
end

-- Status

function update_info()
    local resp = send("song-info", nil, nil, "get");
    if (resp == nil) then
        tid = libs.timer.timeout(update_info, 500);
        return;
    end
    if (resp ~= nil) then
        local info = libs.data.fromjson(resp.content);
        local title;
        if (info.title ~= nil) then
            title = info.title;
        end
        if (info.artist ~= nil) then
            if (title ~= nil) then
                title = title .. " - " .. info.artist;
            else
                title = info.artist;
            end
        end
        if (title ~= nil) then
            libs.server.update({ id = "title", text = title });
        end
        -- if (info.album ~= nil) then
        --     libs.server.update({ id = "album", text = info.album });
        -- end
        if (info.imageSrc ~= nil) then
            local imgHttpUrl = string.gsub(info.imageSrc, "^https://", "http://");
            libs.server.update({ id = "cover", image = imgHttpUrl });
        end
        -- else
        --     libs.server.update({ id = "title", text = "[Not Playing]" });
        --     libs.server.update({ id = "artist", text = "" });
        --     libs.server.update({ id = "album", text = "" });
        --     libs.server.update({ id = "cover", image = nil });
        -- end
        tid = libs.timer.timeout(update_info, 500);
    end
end

-- Actions

--@help Authorize Youtube Music
actions.authorize_tap = function()
    auth();
end
--@help Play or Pause
actions.playpause = function()
    pcall(send, "toggle-play");
end
--@help Play previous track
actions.previous = function()
    pcall(send, "previous");
end
--@help Play next track
actions.next = function()
    pcall(send, "next");
end
--@help Like current track
actions.like = function()
    pcall(send, "like");
end
--@help Dislike current track
actions.dislike = function()
    pcall(send, "dislike");
end
--@help Toggle mute
actions.mute = function()
    pcall(send, "toggle-mute");
end
--@help Volume slider
actions.volume_change = function(vol)
    pcall(send, "volume", "volume", vol);
end
