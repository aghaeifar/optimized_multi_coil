function opt_summary(do_opt_postproc, do_figure_final_position, do_figure_compare, do_design_compare)
% 
% Show summary of the optimization results for a signle or multiple profiles
%   

if nargin < 1 
    do_opt_postproc = false;
end
if nargin < 2
    do_figure_final_position = false;
end
if nargin < 3
    do_figure_compare = false;
end
if nargin < 4
    do_design_compare = false;
end
%% Select the folders contains optimization results 
listing = uipickfiles; % https://de.mathworks.com/matlabcentral/fileexchange/10867
if isequal(listing, 0)
    return
end

%% Execute post processing if wasn't called before
if do_opt_postproc
    for o=1:numel(listing)
        load(fullfile(listing{o}, 'opt_results.mat'), 'param', 'finalCoilPos', 'initCoilPos');
        % -> FoV setup
        fov.fov             = param.fov;        % mm
        fov.fov_size        = param.fov_size;   % fov matrix size, Resolution = fov.fov ./ fov.fov_size
        fov.voxel_offset    = (fov.fov(2,:)-fov.fov(1,:)) ./ fov.fov_size / 2;
        fov.dim_start       = fov.fov(1,:) + fov.voxel_offset;
        fov.dim_stop        = fov.fov(2,:) - fov.voxel_offset;
        fov.dim_skip        = (fov.dim_stop - fov.dim_start) ./ (fov.fov_size-1);
        fov.dim_x           = fov.dim_start(1):fov.dim_skip(1):fov.dim_stop(1);
        fov.dim_y           = fov.dim_start(2):fov.dim_skip(2):fov.dim_stop(2);
        fov.dim_z           = fov.dim_start(3):fov.dim_skip(3):fov.dim_stop(3);
        [fov.fov_x, fov.fov_y, fov.fov_z] = ndgrid(fov.dim_x, fov.dim_y, fov.dim_z);
        % <- FoV setup
        % -> post processing
        opt_post = opt_postproc(finalCoilPos, initCoilPos, param, fov);
        save(fullfile(listing{o}, 'opt_post_results.mat'), 'opt_post');
        % <- post processing
    end
end

%% Make and save a plot of results for individual optimizations
if do_figure_final_position
    h_fig = figure('NumberTitle','off','Position', [100, 100, 1700, 800]);
    for o=1:numel(listing)
        load(fullfile(listing{o}, 'opt_results.mat'), 'param', 'finalCoilPos', 'initCoilPos');
        load(fullfile(listing{o}, 'opt_progress.mat'), 'progress');
        load(param.b0mapTrain_Add{1}, 'brain');
        b0map = permute(brain.b0map .* brain.mask, [2 1 3]); % permute is required since we later use 'slice' function
        % -> Make a figure of results
        clf;
        set(h_fig, 'Name', strrep(listing{o}, '_', ' '));
        subaxis(2,3,[1 2 4 5], 'SpacingVertical', 0.05, 'SpacingHorizontal', 0.05, 'MarginLeft', 0.05, 'MarginRight', 0.05);
        coilpos = coil_pos_make(finalCoilPos.z(:), finalCoilPos.theta(:), finalCoilPos.r(:), param.cylnR, 50, param.coilShape); % div = 50
        coil_pos_plot(coilpos);
        xlim(1.2*[-param.cylnR param.cylnR]); ylim(1.2*[-param.cylnR param.cylnR]); zlim([param.coilZLL-param.coilRUL, param.coilZUL+param.coilRUL]);

        subaxis(2,3,3, 'SpacingVertical', 0.05, 'SpacingHorizontal', 0.05, 'MarginLeft', 0.05, 'MarginRight', 0.05);
        yyaxis left; ylabel(['std of ' num2str(size(progress.shim_std,1)) 'brains B0 map']);
        plot(progress.shim_std', '-');
        yyaxis right; ylabel('Total Error');
        plot(progress.total_err);

        subaxis(2,3,6, 'SpacingVertical', 0.05, 'SpacingHorizontal', 0.05, 'MarginLeft', 0.05, 'MarginRight', 0.05);
        set(gca, 'visible' ,'off');
        h = slice(b0map, round(brain.pixel(1)/2), round(brain.pixel(2)/2), round(brain.pixel(3)/2));
        set(h,'edgecolor','none'); xlabel('X'); ylabel('Y'); zlabel('Z');
        caxis([-150 150]); colormap jet;
        set(gca, 'XTick', [1 brain.pixel(1)], 'XTickLabel', {num2str(brain.fov(1,1)/2), num2str(brain.fov(2,1)/2)}...
               , 'YTick', [1 brain.pixel(2)], 'YTickLabel', {num2str(brain.fov(1,2)/2), num2str(brain.fov(2,2)/2)}...
               , 'ZTick', [1 brain.pixel(3)], 'ZTickLabel', {num2str(brain.fov(1,3)/2), num2str(brain.fov(2,3)/2)});
        view(145,22); grid on; axis tight equal  

        ax = axes('Position',[0 0 .1 1],'Visible','off');
        text(ax, 0.4,0.5, sprintf('Current Limit\n%s', num2str(param.shimCUL', '±%2.1f\n')));
        savefig(h_fig, fullfile(listing{o}, 'figure.fig'));
        % <- Make a figure of results   
    end
end

%% plot the performances to compare
if do_figure_compare
    path2opt_results = fileparts(listing{1});
    shim_scope  = {'global', 'slice_wise_tra', 'slice_wise_sag', 'slice_wise_cor'};
    shim_method = {'lsqlin', 'pinv'};
    coil_pos    = {'optimized', 'symmetric'};
    fig_name    = {'Position optimized design & constraint shimming', 'Position optimized design & unconstraint shimming', 'Symmetric design & constraint shimming', 'Symmetric design & unconstraint shimming'};
    fig_vis     = {'on', 'off', 'off', 'off'};
    subid       = [1 2 4 5];

    colors      = distinguishable_colors(numel(listing)+1); % http://www.mathworks.com/matlabcentral/fileexchange/29702-generate-maximally-perceptually-distinct-colors
    h_plot      = cell((numel(listing)+1)*numel(shim_scope),1);
    s_plot      = cell(numel(listing)+1,1);

    for m=1:numel(coil_pos)
        for n=1:numel(shim_method) 
            fig_ind = n+(m-1)*numel(shim_method);
            h_fig = figure('visible', fig_vis{fig_ind}, 'Name',fig_name{fig_ind},'NumberTitle','off', 'Position', [100, 100, 1700, 800]);
            set(h_fig,'CreateFcn','set(gcf,''Visible'',''on'')'); % this makes the figure visiable when is clicked to open
            for o=1:numel(listing) % # of found valid folders (profiles)
                load(fullfile(listing{o}, 'opt_post_results.mat') , 'opt_post');
                for p=1:numel(shim_scope)
                    subaxis(2,3,subid(p), 'SpacingVertical', 0.05, 'SpacingHorizontal', 0.02, 'MarginLeft', 0.02, 'MarginRight', 0.02, 'MarginTop', 0.05, 'MarginBottom', 0.05);
                    h_plot{(o-1)*numel(shim_scope)+p} = plot(opt_post.(coil_pos{m}).(shim_method{n}).(shim_scope{p}).std, 'Color', colors(o,:));
                    hold on; ylim([0 90]); title(shim_scope{p}, 'Interpreter', 'none');
                    [~, fname, ~] = fileparts(listing{o});
                    s_plot{o} = strrep(fname, '_', ' ');

                    h_plot{numel(listing)*numel(shim_scope)+p} = plot(opt_post.(coil_pos{2}).(shim_method{n}).(shim_scope{p}).std, '--', 'Color', colors(end,:));
                    s_plot{numel(listing)+1} = ['Symmetric (' strrep(fname, '_', ' ') ')'];
                end
            end
            hL = subaxis(2,3,[3 6]);  
            poshL = get(hL,'position'); 
            gr = reshape(repmat(1:numel(listing)+1, 1, numel(shim_scope)), numel(listing)+1, numel(shim_scope))';
            lgd = clickableLegend([h_plot{:}]', s_plot(:), 'groups', gr(:)'); % https://mathworks.com/matlabcentral/fileexchange/21799-clickablelegend-interactive-highlighting-of-data-in-figures
            set(lgd,'position',poshL, 'Interpreter', 'none');         
            axis(hL,'off'); 
            savefig(h_fig, fullfile(path2opt_results, ['figure ' fig_name{fig_ind} '.fig'])); % if you are using matlab 2016b or older, the figure legend won't be saved properly
            if strcmp(fig_vis{fig_ind}, 'off')
                close(h_fig)
            end
        end % for n=1:numel(shim_method) 
    end % for m=1:numel(coil_pos)
end % if do_figure_compare

%% evaluate designs; size of coils and amount of currents
if do_design_compare
    coils_sz   = zeros(numel(listing), 33);
    coils_curr = zeros(numel(listing), 33);
    RowNames   = cell(numel(listing), 1);
    for o=1:numel(listing)
        load(fullfile(listing{o}, 'opt_results.mat'), 'param', 'finalCoilPos', 'initCoilPos');
        load(fullfile(listing{o}, 'opt_post_results.mat'), 'opt_post');
        allCurr             =  cell2mat(opt_post.optimized.lsqlin.global.coef);
        coils_sz(o, :)      = [finalCoilPos.r; sum(finalCoilPos.r)];
        coils_curr(o, :)    = [max(allCurr, [], 2); sum(max(allCurr, [], 2))];
        RowNames{o}         = param.name;
    end
    T = table(coils_sz(:,end), coils_curr(:,end), 'RowNames',RowNames, 'VariableNames',{'Sum_Coil_Size','Sum_Max_Current'})
end
% for o=1:numel(listing)
%     load(fullfile(listing{o}, 'opt_results.mat'), 'param', 'finalCoilPos');
%     subaxis(1,numel(listing),o, 'SpacingVertical', 0.01, 'SpacingHorizontal', 0.01, 'MarginLeft', 0.01, 'MarginRight', 0.01, 'MarginTop', 0.01, 'MarginBottom', 0.01);   
%     coilpos = coil_pos_make(finalCoilPos.z(:), finalCoilPos.theta(:), finalCoilPos.r(:), param.cylnR, 50, param.coilShape); % div = 50
%     coil_pos_plot(coilpos);
%     xlim(1.2*[-param.cylnR param.cylnR]); ylim(1.2*[-param.cylnR param.cylnR]); zlim([param.coilZLL-param.coilRUL, param.coilZUL+param.coilRUL]);
%     title(param.name, 'interpreter', 'none');    
% end