import math, sys
W, H = 44, 26  # wide-enough canvas, trimmed later
thick = float(sys.argv[1]) if len(sys.argv)>1 else 8.0
dotr  = float(sys.argv[2]) if len(sys.argv)>2 else 8.0
dotx, doty = 84, 8
def dist_to_seg(px, py, x1, y1, x2, y2):
    vx, vy = x2-x1, y2-y1
    wx, wy = px-x1, py-y1
    L2 = vx*vx+vy*vy
    if L2 == 0: return math.hypot(px-x1, py-y1)
    t = max(0, min(1, (wx*vx+wy*vy)/L2))
    return math.hypot(px-(x1+t*vx), py-(y1+t*vy))
# real ydot geometry (viewBox 100): left arm, stem, short right arm, dot
segments = [((27,17),(50,48)), ((50,48),(50,83)), ((50,48),(60,33))]
for ry in range(H):
    line = []
    for rx in range(W):
        px = rx/(W-1)*100 + 1
        py = ry/(H-1)*100
        d = min(dist_to_seg(px,py,*a,*b) for a,b in segments)
        ddot = math.hypot(px-dotx, py-doty)
        c = '@' if d < thick or ddot < dotr else ' '
        line.append(c)
    print(''.join(line).rstrip())
