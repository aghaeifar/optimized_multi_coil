%%% here you need to believe me that it gives correct calculation of
%%% magnetic field coming from any current element(s) :-)


function B=b1sim(current,fov_grids)

fz=zeros(size(fov_grids,1),1);

for i=1:length(current)
    % squared lengths of the current edge
    %a=repmat(norm(current{i}.start-current{i}.stop).^2,[size(fov_grids,1),1]);
    a=norm(current{i}.start-current{i}.stop).^2;
    
    % 2 times inner products between vectors pointing from i-th node in the
    % grid and vector pointing from the start of current edge to its stop
    if norm(current{i}.stop-current{i}.start) ~= 0
        
        temp1 = repmat(current{i}.stop-current{i}.start,[size(fov_grids,1),1]);
        temp2 = repmat(current{i}.start,[size(fov_grids,1),1])-fov_grids;
        b=2.*(sum(temp1.*temp2,2));
        % squared lengths of vectors pointing from the i-th node of the grid to
        % the start of current edge
        c=sum(temp2.^2,2);

        s1=current{i}.start;
        s1=repmat(s1,[size(fov_grids,1),1]);
        s2=current{i}.stop;
        s2=repmat(s2,[size(fov_grids,1),1]);    

        qz=(s2(:,1)-s1(:,1)).*(s1(:,2)-fov_grids(:,2));
        qz = qz-(s2(:,2)-s1(:,2)).*(s1(:,1)-fov_grids(:,1));

        fz=fz+integral_exact(qz,a,b,c);
    else
        display('!!!! There is a zero length edge !!!!')
    end

end;

B=fz/1e4;

return;



function output=integral_exact(q,a,b,c)
% integral{(q+p*t)/sqrt(c+b*t+a*t^2).^3}dt, t from 0 to 1
% specific to Bz field component (in this case p = 0)
a = b*0 + a;
denom = 4.*a.*c-b.^2;
output=q.*(2.*(2.*a+b)./denom./sqrt(a+b+c)-2.*b./denom./sqrt(c));

return;
