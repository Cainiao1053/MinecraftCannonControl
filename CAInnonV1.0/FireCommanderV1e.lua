function DrawBackground(w,h)
    term.clear();
    paintutils.drawFilledBox(1,1,w,h,colors.white);
    paintutils.drawFilledBox(1,1,w,1,colors.blue);
    term.setBackgroundColor(colors.blue);
    term.setTextColor(colors.orange);
    local info = "CAInnon"
    term.setCursorPos(w/2-string.len(info)/2,1);
    term.write(info);
    term.setBackgroundColor(colors.white);
    term.setTextColor(colors.black);
end

function Panel()
    while true do
    local cmd = {}
    local w,h = term.getSize()
    DrawBackground(w,h);
    local info = "Status: "..switch;
    term.setCursorPos(w/2-string.len(info)/2,2);
    term.write(info);
    info = "Player Mode"
    term.setCursorPos(w/2-string.len(info)/2,3);
    term.write(info);
    info = "Ship Mode"
    term.setCursorPos(w/2-string.len(info)/2,4);
    term.write(info);
    info = "Location Mode"
    term.setCursorPos(w/2-string.len(info)/2,5);
    term.write(info);
    info = "Firing Mode: "..MODE;
    term.setCursorPos(w/2-string.len(info)/2,6);
    term.write(info);
    info = "Horizontal Dev:"..string.format("%.1f",horfix);
    term.setCursorPos(w/2-string.len(info)/2,7);
    term.write(info);
    term.setCursorPos(10,7);
    term.write("-----");
    term.setCursorPos(35,7);
    term.write("+++++");
    info = "Vertical Dev: "..string.format("%.1f",verfix);
    term.setCursorPos(w/2-string.len(info)/2,8);
    term.write(info);
    term.setCursorPos(10,8);
    term.write("-----");
    term.setCursorPos(35,8);
    term.write("+++++");
    local evn,but,cursx,cursy = os.pullEvent("mouse_click");
    if cursy == 2 then
        if EXEMODE ~= 0 then
            EXEMODE = 0;
            switch ="off";
            DrawBackground(w,h)
            info = "System Paused";
            term.setCursorPos(w/2-string.len(info)/2,3);
            term.write(info);
            sleep(0.4);
            cmd = {EXEMODE};
            for i = 1, #computerID do
                rednet.send(computerID[i],cmd)
            end
        else
            DrawBackground(w,h)
            info = "System Already Paused";
            term.setCursorPos(w/2-string.len(info)/2,3);
            term.write(info);
            sleep(0.4);
        end
    elseif cursy == 3 then
        DrawBackground(w,h);
        info = "Type in Playername";
        term.setCursorPos(w/2-string.len(info)/2,2);
        term.write(info);
        info = "Scan For Player";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        local evn, but, cursxx, cursyy = os.pullEvent("mouse_click");
        if cursyy == 2 then
        DrawBackground(w,h);
        info = "Enter the target Player";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        term.setCursorPos(w/2-3,4);
        targetplayer = read();
        EXEMODE = 1;
        info = "Aiming to that shit";
        term.setCursorPos(w/2-string.len(info)/2,5);
        term.write(info);
        switch = "Player"
        cmd = {EXEMODE,targetplayer};
        for i = 1, #computerID do
            rednet.send(computerID[i],cmd)
        end
        elseif cursyy == 3 then
            DrawBackground(w,h);
            players = {}
            E = coord.getEntities(range);
            playernum = 0;
            for key, val in pairs(E) do
                if val.type == "minecraft:player" then
                    playernum = playernum + 1;
                    players[playernum] = val.name;
                    term.setCursorPos(w/2-string.len(players[playernum])/2,playernum+1);
                    term.write(players[playernum]);
                end
            end
            local evn,but,cursxxx,cursyyy = os.pullEvent("mouse_click");
            if cursyyy>1 then
                if players[cursyyy-1]~=nil then
                    targetplayer = players[cursyyy-1];
                    EXEMODE = 1;
                    DrawBackground(w,h)
                    info = "Aiming to that shit";
                    term.setCursorPos(w/2-string.len(info)/2,5);
                    term.write(info);
                    switch = "Player"
                    cmd = {EXEMODE,targetplayer};
                    for i = 1, #computerID do
                        rednet.send(computerID[i],cmd)
                    end
                end
            end
        end
        sleep(0.3);
    elseif cursy == 4 then
        DrawBackground(w,h);
        info = "Type in Shipname";
        term.setCursorPos(w/2-string.len(info)/2,2);
        term.write(info);
        info = "Scan For Ship";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        local evn,but,cursxx,cursyy = os.pullEvent("mouse_click");
        if cursyy == 2 then
        DrawBackground(w,h);
        info = "Enter the target Vehicle";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        term.setCursorPos(w/2-3,4);
        targetship = read();
        EXEMODE = 2;
        switch = "Ship";
        info = "Aiming to that shit";
        term.setCursorPos(w/2-string.len(info)/2,5);
        term.write(info);
        cmd = {EXEMODE,targetship};
        for i = 1, #computerID do
            rednet.send(computerID[i],cmd)
        end
        elseif cursyy ==3 then
            DrawBackground(w,h);
            ships = {}
            S = coord.getShips(range);
            shipnum = 0;
            for key, val in pairs(S) do
                    shipnum = shipnum + 1;
                    ships[shipnum] = val.slug;
                    term.setCursorPos(w/2-string.len(ships[shipnum])/2,shipnum+1);
                    term.write(ships[shipnum]);
            end
            local evn,but,cursxxx,cursyyy = os.pullEvent("mouse_click");
            if cursyyy>1 then
                if ships[cursyyy-1]~=nil then
                    targetship = ships[cursyyy-1];
                    EXEMODE = 2;
                    DrawBackground(w,h);
                    info = "Aiming to that shit";
                    term.setCursorPos(w/2-string.len(info)/2,5);
                    term.write(info);
                    switch = "Ship"
                    cmd = {EXEMODE,targetship};
                    for i = 1, #computerID do
                        rednet.send(computerID[i],cmd)
                    end
                end
            end
        end
        sleep(0.3);
    elseif cursy == 5 then
        DrawBackground(w,h);
        info = "Enter the target x axis";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        term.setCursorPos(w/2-3,4);
        xtgt0 = tonumber(read());
        info = "Enter the target z axis";
        term.setCursorPos(w/2-string.len(info)/2,5);
        term.write(info);
        term.setCursorPos(w/2-3,6);
        ztgt0 = tonumber(read())
        info = "Enter the target y axis";
        term.setCursorPos(w/2-string.len(info)/2,7);
        term.write(info);
        term.setCursorPos(w/2-3,8);
        ytgt0 = tonumber(read());
        if type(xtgt0)=="number" and type(ztgt0)=="number" and type(ytgt0)=="number" then
            xtgt1 = xtgt0;
            ztgt1 = ztgt0;
            ytgt1 = ytgt0;
            EXEMODE = 3;
            switch = "Location"
            info = "Aiming to that shit";
            term.setCursorPos(w/2-string.len(info)/2,9);
            term.write(info);
            cmd = {EXEMODE,xtgt1,ztgt1,ytgt1};
            for i = 1, #computerID do
                rednet.send(computerID[i],cmd)
            end
        else
            info = "Invalid Values";
            term.setCursorPos(w/2-string.len(info)/2,9);
            term.write(info);
        end
    elseif cursy ==6 then
        if MODE == "flat" then
            MODE = "drop"
        elseif MODE == "drop" then
            MODE = "flat";
        else
            MODE = "flat";
        end
        cmd = {4,MODE};
        for i = 1, #computerID do
            rednet.send(computerID[i],cmd);
        end
        sleep(0.1);
    elseif cursy == 7 then
        if cursx <=15 then
            horfix = horfix - 0.2
        elseif cursx>=35 then
            horfix = horfix + 0.2;
        elseif cursx >20 and cursx < 30 then
            horfix = 0;
        end
        if horfix >20 then
            horfix = 20
        elseif horfix<-20 then
            horfix = -20;
        end
        cmd = {5,horfix};
        for i = 1, #computerID do
            rednet.send(computerID[i],cmd);
        end
    elseif cursy == 8 then
        if cursx <=15 then
            verfix = verfix - 0.2;
        elseif cursx >=35 then
            verfix = verfix + 0.2;
        elseif cursx > 20 and cursx < 30 then
            verfix = 0;
        end
        if verfix > 4 then
            verfix = 4;
        elseif verfix < -5 then
            verfix = -5;
        end
        cmd = {6,verfix};
        for i = 1, #computerID do
            rednet.send(computerID[i],cmd);
        end
    end
    sleep(0.1);
end
end

computerID = {0,1,2};
mod = peripheral.wrap("right");
mod.open(386);
rednet.open("right");

MODE = "flat";
EXEMODE = 0;
switch = "off";

horfix = 0;
verfix = 0;
range = 500;

Panel();