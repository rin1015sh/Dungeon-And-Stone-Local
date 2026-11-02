"""균열 설계도의 줄무늬 바닥 어긋남 찾기(카펫·레일·발판·계단·홈 — 2026-11-02 사용자 "카펫이랑 입구가 안 맞아떨어지는 곳").
  python3 tools/rift_strip_check.py [타일id,타일id,...]
이웃한 두 줄(가로) 또는 두 열(세로)에서 같은 줄무늬 타일의 띠가 겹치면서 폭·위치가 달라지는데, 그 차이 칸이 벽이 아닌 곳을 적는다.
광차·분기 선로·잔해처럼 일부러 끊은 곳도 나오니 지도(data/maps/rifts/)를 보고 판단한다.
"""
import json,glob,sys
tiles=json.load(open('data/tiles.json')); tiles=tiles['tiles'] if isinstance(tiles,dict) else tiles
by={t['id']:t for t in tiles}
STRIPS=sys.argv[1].split(',') if len(sys.argv)>1 else ['it_carpet','gm_rail','gm_planks','it_stairs','gc_stairs','gm_stairs','bf_stairs','it_groove','bf_road']
def runs(seq, tid):
    out=[];i=0
    while i<len(seq):
        if seq[i]==tid:
            j=i
            while j+1<len(seq) and seq[j+1]==tid: j+=1
            out.append((i,j)); i=j+1
        else: i+=1
    return out
total=0
for f in sorted(glob.glob('data/maps/rifts/*.json')):
    d=json.load(open(f)); leg=d['legend']; rows=[[leg.get(c) for c in r] for r in d['rows']]
    H=len(rows); W=len(rows[0])
    cols=[[rows[y][x] for y in range(H)] for x in range(W)]
    wall=lambda t: t is None or by.get(t,{}).get('kind')=='wall'
    name=f.split('/')[-1][5:-5]
    found=[]
    for tid in STRIPS:
        for axis,lines in (('세로',rows),('가로',cols)):
            for k in range(len(lines)-1):
                A=runs(lines[k],tid); B=runs(lines[k+1],tid)
                for a in A:
                    for b in B:
                        if a[1]<b[0] or b[1]<a[0] or a==b: continue
                        # cells in the symmetric difference: are they walls in the line that lacks the strip?
                        diff=[]
                        for i in range(min(a[0],b[0]),max(a[1],b[1])+1):
                            inA=a[0]<=i<=a[1]; inB=b[0]<=i<=b[1]
                            if inA!=inB:
                                other=lines[k+1][i] if inA else lines[k][i]
                                if not wall(other): diff.append(i)
                        if diff:
                            found.append((tid,axis,k,a,b,diff))
    if found:
        print('==',name)
        for tid,axis,k,a,b,diff in found:
            if axis=='세로': print('  %s 줄 %d→%d: x %d~%d → %d~%d (어긋난 칸 x %s)'%(tid,k,k+1,a[0],a[1],b[0],b[1],diff))
            else: print('  %s 열 %d→%d: y %d~%d → %d~%d (어긋난 칸 y %s)'%(tid,k,k+1,a[0],a[1],b[0],b[1],diff))
        total+=len(found)
print('total',total)
