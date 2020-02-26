function parseOutputToSTL(obj, component)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% Flag indicating whether we are done or not
contFlag = 1;

while contFlag
    if length(component) > 1
        component = component(1);
    end
    
    indexToUse = getIndexToExploreModel(component);
    
    if indexToUse > 0
        % We need to continue our Depth-First Search through blocks!
        component = getNextComponentInDFS(obj, component, indexToUse);
    else
        % All inputs to the current component has a sub-signal assigned to
        % it. This means we are ready to build the STL formula for this
        % component!
        blockType = get(component,'BlockType');
        maskType = get(component, 'MaskType');
        
        % If we have visited the block MANY times, it's an infinite loop
        if obj.timesVisited(obj.systemHandle == component) > 20
            % Log the output of the delay block that necessarily is part of
            % the infinite loop
            if strcmp(blockType, 'Delay') || ...
                    strcmp(blockType, 'UnitDelay') || ...
                    ~isempty(strfind(get(component,'Name'), 'Unit Delay'))
                disp(['Infinite loop detected! Logging output of ' get(component,'Name')]);
                obj.logOneBlock(component);
            end
        end
        
        if strcmp(blockType,'Abs')
            obj.absToSTL(component); % generic operator
        elseif strcmp(blockType,'Constant')
            obj.constantToSTL(component);
        elseif strcmp(blockType,'DataTypeConversion')
            obj.dataTypeConversionToSTL(component);
        elseif strcmp(blockType,'Delay')
            obj.delayToSTL(component);
        elseif strcmp(blockType,'From')
            obj.fromToSTL(component);
        elseif strcmp(blockType,'Gain')
            obj.gainToSTL(component); % generic operator
        elseif strcmp(blockType,'Goto')
            obj.gotoToSTL(component);
        elseif strcmp(blockType,'Ground')
            obj.groundToSTL(component);
        elseif strcmp(blockType,'Inport')
            obj.inportToSTL(component);
        elseif strcmp(blockType,'Logic')
            obj.logicToSTL(component); % generic operator
        elseif strcmp(blockType,'MinMax')
            obj.minMaxToSTL(component); % generic operator
        elseif strcmp(blockType, 'Mux')
            obj.muxToSTL(component);
        elseif strcmp(blockType,'MultiPortSwitch')
            obj.multiPortSwitchToSTL(component);
        elseif strcmp(blockType,'Outport')
            obj.outportToSTL(component);
            % We have reached the outport - set contFlag to 0 to stop loop
            contFlag = 0;
        elseif strcmp(blockType,'Product')
            obj.productToSTL(component); % generic operator
        elseif strcmp(blockType,'RelationalOperator')
            obj.relationalOperatorToSTL(component); % generic operator
        elseif strcmp(blockType, 'Rounding')
            obj.roundingToSTL(component);
        elseif strcmp(blockType,'SampleTimeMath')
            obj.sampleTimeMathToSTL(component);
        elseif strcmp(blockType,'Saturate')
            obj.saturationBlockToSTL(component);
        elseif strcmp(blockType,'Signum')
            obj.signumToSTL(component); % generic operator
        elseif strcmp(blockType,'Sqrt')
            obj.sqrtToSTL(component);
        elseif strcmp(blockType,'SubSystem')
            % Here, we can define STL formulas for template subsystems. 
            % Volvo templates have been removed. 
            % TODO: Make sure all the generated ones are correct!
            if strfind(get(component,'Name'),'notAlways')
                obj.notAlwaysToSTL(component);
            elseif strfind(get(component,'Name'),'Saturation')
                obj.saturationToSTL(component);
            elseif strfind(get(component, 'Name'), 'evChanges')
                obj.evChangesToSTL(component);
            elseif strfind(get(component, 'Name'), 'resetCounter')
                component = obj.resetCounterToSTL(component);
            elseif strfind(get(component, 'Name'), 'SR_FF')
                obj.srffToSTL(component);
            elseif strfind(get(component,'Name'),'Detect') & ...
                    strfind(get(component,'Name'), 'Decrease') %#ok<*AND2>
                obj.detectDecreaseToSTL(component);
            elseif strfind(get(component,'Name'),'Detect') & ...
                    strfind(get(component,'Name'), 'Increase') %#ok<*STRIFCND>
                obj.detectIncreaseToSTL(component);
            else
                %We have to dive into the subsystem
                obj.subSystemToSTL(component);
            end
        elseif strcmp(blockType,'Sum')
            component = obj.sumToSTL(component); % generic operator
        elseif strcmp(blockType,'Switch')
            obj.switchToSTL(component);
        elseif strcmp(blockType,'UnitDelay')
            obj.unitDelayToSTL(component);
        else
            error(['Have to define what to do for ' get(component,'Name') '(' blockType ')']);
        end
        
        if obj.atGotoBlock
            component = obj.gotoBlock;
            obj.atGotoBlock = 0;
        else
            obj.timesVisited(obj.systemHandle == component) = obj.timesVisited(obj.systemHandle == component) + 1;
            component = obj.parentHandle(obj.systemHandle == component); % "component" here used to be "src"
            
            % Abort if formula is too long
            %if length(obj.subStruct(obj.subCounter - 1).string) > obj.charLimit ...
            %        || obj.tooLongSTLFormula == 1
            % TODO: Implement!
            totalFormulaLength = obj.getTotalFormulaLength();
            if totalFormulaLength > obj.charLimit || obj.tooLongSTLFormula == 1
                % If the last sub-formula created is longer than
                % charLimit characters, abort!
                disp(['**** The formula is now longer than the limit of ' num2str(obj.charLimit) ' characters! Aborting ...']);
                obj.tooLongSTLFormula = 1;
                contFlag = 0;
                
                if ~isdir([obj.resultsFolder '/STLFiles/TooLong'])
                    mkdir([obj.resultsFolder '/STLFiles/TooLong']);
                end
                
                % Check if the file is currently open
                if ~isempty(fopen(obj.fileID))
                    % Close the file (IF IT IS OPEN!)
                    fclose(obj.fileID);
                    
                    % Move the file into TooLong directory
                    movefile(obj.fileName,[obj.resultsFolder '/STLFiles/TooLong/' obj.requirement '.stl']);
                end
                
                
            end
        end
    end
end
end


function indexToUse = getIndexToExploreModel(component)
% component is the current parent
conn = get(component,'PortConnectivity');
% Find a source that has no signal name yet
indexToUse = -1;

for tmp_cnt=1:length(conn)
    if ~isempty(conn(tmp_cnt).SrcBlock)
        tmp_ph = get_param(conn(tmp_cnt).SrcBlock,'PortHandles');
        tmp_ph_name = get(tmp_ph.Outport,'Name');
        try
            hej = tmp_ph_name{1};
            if isempty(hej)
                % The signal is not a bus
                indexToUse = tmp_cnt;
            end
        catch
            
        end
        if isempty(tmp_ph_name)
            % This index should be used to further explore
            % model
            indexToUse = tmp_cnt;
            break
        end
    end
end
end

function newComponent = getNextComponentInDFS(obj, component, indexToUse)
% We need to continue our Depth-First Search through blocks!
% src is the current child
conn = get(component,'PortConnectivity');
src = conn(indexToUse).SrcBlock;

if isempty(find(obj.systemHandle == src,1)) || isempty(find(obj.parentHandle == component,1))
    obj.systemHandle(end+1) = src;
    obj.parentHandle(end+1) = component;
    obj.timesVisited(end+1) = 1;
else
    obj.timesVisited(obj.systemHandle == component) = obj.timesVisited(obj.systemHandle == component) + 1;
end

if obj.timesVisited(obj.systemHandle == component) > 20
    tmp_block_type = get(component,'BlockType');
    
    if strcmp(tmp_block_type, 'Delay') || ...
            strcmp(tmp_block_type, 'UnitDelay') || ...
            ~isempty(strfind(get(component,'Name'), 'Unit Delay'))
        disp(['Infinite loop detected! Logging output of ' get(component,'Name')]);
        obj.logOneBlock(component);
    end
end

newComponent = src;
end