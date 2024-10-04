local function mat_mult(A, B)
    local M = {{}, {}, {}}
    for i = 1, 3 do for j = 1, 3 do M[i][j] = A[i][1] * B[1][j] + A[i][2] * B[2][j] + A[i][3] * B[3][j] end end
    return M
end

function get_euler(direction)
    local R
    if direction == "east" then
        R = { {0, 0, 1}, {0, 1, 0}, {-1, 0, 0} }
    elseif direction == "west" then
        R = { {0, -1, 0}, {1, 0, 0}, {0, 0, 1} }
    elseif direction == "south" then
        R = { {1, 0, 0}, {0, 1, 0}, {0, 0, 1} }
    elseif direction == "north" then
        R = { {-1, 0, 0}, {0, -1, 0}, {0, 0, -1} }
    else
        error("No direction selected")
    end

    local M = ship.getRotationMatrix()
    M = mat_mult(M, R)

    local yaw, pitch, roll = math.atan2(-M[1][3], M[3][3]), -math.asin(M[2][3]), math.atan2(M[2][1], M[2][2])
    return yaw, pitch, roll
end

function getCannonTable(filename,n) --get Polyfit functions
    local file = io.open(filename);
    local C0raw = {};
    local C0 = {};
    for lines in io.lines(filename) do
        table.insert(C0raw,tonumber(lines));
    end
    file:close();
    for i = 1,5 do
        C0[i] = C0raw[i+5*(n-1)];
    end
    return C0;
end

function getRangeLimit(filename,n) --get range limit
    local file = io.open(filename);
    local limit = {};
    for lines in io.lines(filename) do
        table.insert(limit,tonumber(lines));
    end
    file:close();
    min = limit[2*n - 1];
    max = limit[2*n];
    return min, max;
end

function CannonPoly(C0,C1,diff,w);
    local alpha;
    alpha = C0[1]*w^4+(C0[2]+diff*C1[2]/5)*w^3+(C0[3]+diff*C1[3]/5)*w^2+(C0[4]+diff*C1[4]/5)*w+(C0[5]+diff*C1[5]/5);
    return alpha;
end


function getFlatTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0,C1,minf,maxf,selfVelocity,vxtgt,vztgt) --should run after getting Cs and limits, angles are in deg
    local w = math.sqrt((posx-xtgt)^2+(posz-ztgt)^2);
    local hdiff = ytgt - posy;
    local pitch;
    local tShell = w^1.1/(n*40);
    local yaw = math.atan2(-(xtgt-posx-(vxtgt)*tShell),((ztgt-posz-(vztgt)*tShell)));
    yaw = yaw*180/math.pi
    if yaw<-180 then
        yaw = yaw +360;
    elseif yaw>180 then
        yaw = yaw - 360;
    end
    if w <= minf then
        pitch = w*CannonPoly(C0,C1,0,min)/min+math.atan2(hdiff,w)*180/math.pi;
    elseif w > minf and w < maxf then
        pitch = CannonPoly(C0,C1,hdiff,w);
    elseif w >= maxf then
        pitch = CannonPoly(C0,C1,hdiff,max);
    end
    return pitch,yaw;
end

function getDropTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0d,C1d,C0f,C1f,minf,maxf,mind,maxd,selfVelocity,vxtgt,vztgt)
    local w = math.sqrt((posx-xtgt)^2+(posz-ztgt)^2);
    local hdiff = ytgt - posy;
    local pitch;
    local tShell = w^1.15/(n*40);
    local yaw = math.atan2(-(xtgt-posx-(vxtgt)*tShell),((ztgt-posz-(vztgt)*tShell)));
    yaw = yaw*180/math.pi
    if yaw<-180 then
        yaw = yaw +360;
    elseif yaw>180 then
        yaw = yaw - 360;
    end
    if w <= minf then
        pitch = w*CannonPoly(C0f,C1f,0,minf)/min+math.atan2(hdiff,w)*180/math.pi;
    elseif w >minf and w < mind then
        pitch = CannonPoly(C0f,C1f,hdiff,w)
    elseif w >= mind and w < maxd then
        pitch = CannonPoly(C0d,C1d,hdiff,w);
    elseif w >= maxd then
        pitch = CannonPoly(C0d,C1d,hdiff,maxd);
    end
    return pitch,yaw;
end

function pitchLimit(pitch,uplimit,downlimit)
    if pitch > uplimit then
        pitch = uplimit;
    elseif pitch < downlimit then
        pitch = downlimit;
    end
    return pitch
end

function bearingPD1(ang,angtgt,speedLimit)
    local spd
    local dAng = -(angtgt - ang);
    if dAng >180 then
        dAng = dAng - 360;
    elseif dAng <-180 then
        dAng = dAng + 360;
    end
    spd = ((dAng/15)^3+3*(dAng))
    if spd>speedLimit then
    spd = speedLimit;
    elseif spd<-speedLimit then
    spd = -speedLimit;
    end
    return spd
    end

function bearingPD2(ang,angtgt,speedLimit)
    local spd
    local dAng = -(angtgt - ang);
    if dAng >180 then
        dAng = dAng - 360;
    elseif dAng <-180 then
        dAng = dAng + 360;
    end
    spdfix = ((omegay*math.abs(dAng)));
    if spdfix>3000 then
        spdfix = 3000
    elseif spdfix < -3000 then
        spdfix = -3000
    end
    spd = ((dAng/80)^3+2.5*(dAng))/5 - spdfix/210
    if spd>speedLimit then
    spd = speedLimit;
    elseif spd<-speedLimit then
    spd = -speedLimit;
    end
    return spd
end

local function phaseLimitSharp(targetAngle, direction,shootRange) --for sharp angles, shoot Range between 0 to 90 for fixed mount
local shoot = 0;
    if direction == "south" then --0
    if targetAngle < shootRange or targetAngle > (360-shootRange) then
        shoot = 1;
    end
    elseif direction == "west" then --90
        if targetAngle < (90+shootRange) and targetAngle > (90-shootRange) then
            shoot = 1;
        end
    elseif direction == "north" then --180
        if targetAngle < (180+shootRange) and targetAngle > (180-shootRange) then
            shoot = 1;
        end
    elseif direction == "east" then --270
        if targetAngle < (270+shootRange) and targetAngle > (270-shootRange) then
            shoot = 1;
        end
    end
    return shoot;
end

local function phaseLimitObtuse(targetAngle, direction,shootRange) --for obtuse angles, shoot Range between 90 to 180 for fixed mount
    local shoot = 0;
        if direction == "south" then --0
        if targetAngle < shootRange or targetAngle > (360-shootRange) then
            shoot = 1;
        end
        elseif direction == "west" then --90
            if (targetAngle < (90+shootRange) and targetAngle > 0) or targetAngle >(450 - shootRange) then
                shoot = 1;
            end
        elseif direction == "north" then --180
            if targetAngle < (180+shootRange) and targetAngle > (180-shootRange) then
                shoot = 1;
            end
        elseif direction == "east" then --270
            if (targetAngle < 360 and targetAngle > (270-shootRange)) or targetAngle <(shootRange - 90) then
                shoot = 1;
            end
        end
        return shoot;
    end

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

flatMain = "disk/MainFlatTable.lua";
dropMain = "disk/MainDropTable.lua";
flatErr = "disk/ErrorFlatTable.lua";
dropErr = "disk/ErrorDropTable.lua";
flatRange = "disk/FlatRangeLimitTable.lua";
dropRange = "disk/DropRangeLimitTable.lua";

remoteP = peripheral.wrap("back");
--g = peripheral.wrap("back");
g = {}
guns = remoteP.getNamesRemote()
gunsNum = 0;
for i = 1, #guns do
    if string.find(guns[i],"cbc_cannon_mount") ~=nil then
        gunsNum = gunsNum + 1;
    g[gunsNum] = peripheral.wrap(guns[i]);
    g[gunsNum].disassemble();
    g[gunsNum].assemble();
    end
end
directionAngle = g[1].getYaw();
if math.abs(directionAngle) <1 then
    direction = "south";
elseif math.abs(directionAngle - 90) <1 then
    direction = "west";
elseif math.abs(directionAngle - 180) <1 then
    direction = "north";
elseif math.abs(directionAngle - 270) <1 then
    direction = "east";
end
sleep(0.5);

function getSelfPos()
    local posx, posy, posz;
local selfPos = coord.getCoord();
posx = selfPos.x;
posy = selfPos.y;
posz = selfPos.z;
return posx, posy, posz;
end


commanderID = 9;
playerWhiteList = {};
OPNum = #playerWhiteList;
cID = os.computerID()
--ship.setName("HostileTurret"..cID);
shipWhiteList = {"HostileTurret"}; --class of whitelisted ships
shipWLNum = #shipWhiteList;
gNum = #g;

xtgt = 0; --position of target
ytgt = 60;
ztgt = 0;
vxtgt = 0;
vztgt = 0;
randh = math.random(-100,100)/33;; --random number of horizon plane
randy = math.random(-100,100)/100;; --random number of y

tgtshipx0 = 0;
tgtshipz0 = 0;

MODE = "flat";
n = 4;
pi = math.pi;
EXEMODE = 0;
switch = "off";
t0 = 0;
t = 0;
dt = 0;
horfix = 0;
verfix = 0;
shipyaw = 360; --anti-error
yawAngle = 360;
pitchAngle = 360;

C0f = getCannonTable(flatMain,n);
C1f = getCannonTable(flatErr,n);
C0d = getCannonTable(dropMain,n);
C1d = getCannonTable(dropErr,n);
minf, maxf = getRangeLimit(flatRange,n);
mind, maxd = getRangeLimit(dropRange,n);

function Panel()
    while true do
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
        else
            DrawBackground(w,h)
            info = "System Already Paused";
            term.setCursorPos(w/2-string.len(info)/2,3);
            term.write(info);
            sleep(0.4);
        end
    elseif cursy == 3 then
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
        sleep(0.3);
    elseif cursy == 4 then
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
        sleep(0.1);
    end
    sleep(0.1);
end
end

function commandReceive()
    while true do
    id, command = rednet.receive(nil,2);
if command ~= nil then
    print(1)
if id == commanderID then
    if command[1] == 1 then
        targetplayer = command[2];
        EXEMODE = command[1];
    elseif command[1] == 2 then
        targetship = command[2];
        EXEMODE = command[1];
    elseif command[1] == 3 then
        xtgt1 = command[2]
        ztgt1 = command[3]
        ytgt1 = command[4]
        EXEMODE = command[1];
    elseif command[1] == 4 then
        MODE = command[2];
    elseif command[1] == 5 then
        horfix = command[2];
    elseif command[1] == 6 then
        verfix = command[2];
    end
end
end
end
end

local function EnermySearching()
    while true do       
            getTargetPlayers = coord.getEntities(400);
            tPlayer = 0;
            tShip = 0;
            targetPlayerNum = 0;
            targetShipNum = 0;
            skipPlayer = math.random(1,2);
            targetPlayerGrp = {};
            targetShipGrp = {};
            if skipPlayer == 1 then
            for key, val in pairs(getTargetPlayers) do
                if val.type == "minecraft:player" then
                    isOP = 0;
                    for i =1, OPNum do
                        if val.name == playerWhiteList[i] then
                            isOP = 1;
                        end
                    end
                    if isOP == 0 then
                    targetPlayerNum = targetPlayerNum + 1;
                    targetPlayerGrp[targetPlayerNum] = val.name;
                    tPlayer = 1;
                    end
                end
            end
            if tPlayer == 1 then
                targetplayer = targetPlayerGrp[math.random(1,targetPlayerNum)];
                EXEMODE = 1;
            end
            end
            if tPlayer == 0 then
                getTargetShips = coord.getShips(400);
                for key, val in pairs(getTargetShips) do
                    isWL = 0;
                    for i = 1,shipWLNum do
                        if string.find(val.slug,shipWhiteList[i],1, true) ~= nil then
                            isWL = 1;
                        end
                    end
                    if isWL == 0 then
                        targetShipNum = targetShipNum + 1;
                        targetShipGrp[targetShipNum] = val.slug;
                        tShip = 1;
                    end
                end
                if tShip == 1 then
                    targetship = targetShipGrp[math.random(1,targetShipNum)];
                    EXEMODE = 2;
                end
            end
            if tPlayer == 0 and tShip ==0 then
                EXEMODE = 0;
            else
                sleep(15);
            end
            sleep(0.5);
    end
end

local function AutoFiring()
    sleep(5);
    while true do
    if EXEMODE ~= 0 then
        shoot = phaseLimitSharp(yawAngle,direction,75);
        if shoot == 1 then
        if math.abs(g[1].getYaw()-yawAngle) < 3 and math.abs(g[1].getPitch()-pitchAngle) < 2 then
            for i = 1, gNum do
                g[i].fire();
                randh = math.random(-100,100)/35;
                randy = math.random(-100,100)/100;
            end
            sleep(6);
        end
    end
    end
        sleep(1);
    end
end

function MainThread()
posx, posy, posz = getSelfPos();
while true do
    if EXEMODE ~=0 then
    t = os.clock();
    dt = t-t0;
    t0 = t;
    selfVelocity = 0;
    if EXEMODE ==1 then
    local players = coord.getEntities(400);
    for key, val in pairs(players) do
        if val.type == "minecraft:player" and val.name == targetplayer then
            xtgt = val.x;
            ytgt = val.y;
            ztgt = val.z;
            vxtgt = 45*val.vector.x;
            vztgt = 45*val.vector.z;
        end
    end
    elseif EXEMODE == 2 then
        ships = coord.getShips(400);
        for key, val in pairs(ships) do
            if val.slug == targetship then
                xtgt = val.x;
                ytgt = val.y-2;
                ztgt = val.z;
                vxtgt = (xtgt-tgtshipx0)/dt
                vztgt = (ztgt-tgtshipz0)/dt
                tgtshipx0 = xtgt;
                tgtshipz0 = ztgt;
            end
        end
    elseif EXEMODE == 3 then
        xtgt = xtgt1;
        ytgt = ytgt1;
        ztgt = ztgt1;
    end
if MODE == "flat" then
    pitchAngle,yawAngle = getFlatTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0f,C1f,minf,maxf,selfVelocity,vxtgt,vztgt);
elseif MODE == "drop" then
    pitchAngle, yawAngle = getDropTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0d,C1d,C0f,C1f,minf,maxf,mind,maxd,selfVelocity,vxtgt,vztgt)
end
if yawAngle<0 then --limit for bearing itself
    yawAngle = yawAngle+360;
elseif yawAngle>360 then
    yawAngle = yawAngle-360
end
pitchAngle = pitchAngle+randy;
pitchAngle = pitchLimit(pitchAngle,60,-20);
yawAngle = yawAngle + randh;
--g.setPitch(pitchAngle);
for i = 1, gunsNum do
    g[i].setPitch(pitchAngle);
    g[i].setYaw(yawAngle);
end
print(posx);
print(posy);
print(posz);
else
    sleep(1);
end
sleep(0.15)
end
end

parallel.waitForAny(MainThread,EnermySearching,AutoFiring)