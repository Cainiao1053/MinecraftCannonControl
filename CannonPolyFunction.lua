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

C0 = {};
C1 = {};

function getPitchTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0,C1,min,max,uplimit,downlimit) --should run after getting Cs and limits, angles are in deg
    local w = math.sqrt((posx-xtgt)^2+(posz-ztgt^2));
    local hdiff = ytgt - posy;
    local angle;
    if w <= min then
        angle = w*CannonPoly(C0,C1,0,min)/min+math.atan2(hdiff,w)*180/math.pi;
    elseif w > min and w < max then
        angle = CannonPoly(C0,C1,hdiff,w);
    elseif w >= max then
        angle = CannonPoly(C0,C1,hdiff,max);
    end
    if angle > uplimit then
        angle = uplimit;
    elseif angle < downlimit then
        angle = downlimit;
    end
    return angle;
end