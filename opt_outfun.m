function stop = opt_outfun(x, optimValues, state, param)  
    persistent progress; % I need to retain error value during iterations
    if optimValues.iteration == 0
        progress.shim_std  = [];
        progress.total_err = [];
        progress.coil_pos  = cell(0);
    end
    stop = false; % continute optimization
    prefix = [];
    if ~isempty(getCurrentTask())
        t = getCurrentTask();
        prefix = ['Worker ID: ', sprintf('%2d', t.ID) ' |'];
    end
    if isequal(state, 'done') || isequal(state, 'iter')
        if isequal(state, 'iter') % The algorithm is at the end of an iteration
            progress.total_err = [progress.total_err, optimValues.fval];
            progress.coil_pos{end+1} = x;
            W = evalin('base','whos'); % import properties of all existing variables in workspace
            if sum(strcmp({W(:).name}, 'data_outfuns')) % check whether 'shim_error' exists in workspace
                data_outfuns = evalin('base', 'data_outfuns');
                progress.shim_std  = [progress.shim_std, data_outfuns.shim_std];
            end
            
            % sometime the optimization progress gets boring and needs to be terminated manually, create stop.txt in the target folder and type 1 into the file.
            % the program check stop.txt every 50 iterations
            if mod(optimValues.iteration, 10) == 0
                myManualStop = fullfile(param.savePath, 'stop.txt');
                if exist(myManualStop, 'file') == 2
                    fileID = fopen(myManualStop,'r');
                    if fscanf(fileID,'%d') == 1
                        stop  = true;
                        state = 'done';
                    end
                    fclose(fileID);
                end
            end
        end
        
        prn_prg(optimValues, state, param, progress);
        
        if isequal(state, 'done') % The algorithm is in the final state after the last iteration
            disp('Saving simulation results');
            save(fullfile(param.savePath, 'opt_progress.mat'), 'progress');
        end
    end
end

% print progress
function prn_prg(optimValues, state, param, progress) 
    if isequal(state, 'iter')
        worker_stat = 'running';
    elseif isequal(state, 'done')
        worker_stat = 'finished';    
    end
    
    if ~isempty(getCurrentTask())        
        t = getCurrentTask();
        f_name = fullfile(fileparts(mfilename('fullpath')), 'log.txt');
        mylog = {};
        if exist(f_name, 'file') == 2
            mylog = regexp( fileread(f_name), '\n', 'split');
            mylog(end) = [];
        end
        mylog{t.ID} = sprintf('Worker ID: %d | Iter = %-4d | Loss = %12.1f/%-12.1f | %s | %s', t.ID, optimValues.iteration, optimValues.fval, progress.total_err(1), param.name, worker_stat);
        fid = fopen(f_name, 'w');
        fprintf(fid, '%s\n', mylog{:}); % save to file
        fclose(fid);        
        fprintf('%s\n', mylog{:}); % display in screen
    else
        fprintf('Iter = %-4d | Loss = %12.1f/%-12.1f | %s\n', optimValues.iteration, optimValues.fval, progress.total_err(1), param.name);
    end 
end
