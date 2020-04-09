function outportToSTL(obj, component)
%FUNCTION   Description goes here.
%

% We have arrived at our final destination
% Save the final formula in the corresponding STL file
inputName = obj.getInputNames(component);
[startDelay, endDelay, ~, ~, FPIstruct] = obj.getSubStructInfo(inputName{1});

if obj.subSystemLevel > 0
    % We're in a subSystem - do nothing!
else
    % In the start of the file, write the string about skipped signals
    fprintf(obj.fileID,obj.skippedString);
    fprintf(obj.fileID,'\n');
    
    % Then, write the parameters and their values
    obj.paramString = obj.paramString(1:end-2);
    fprintf(obj.fileID,obj.paramString);
    fprintf(obj.fileID,'\n\n');
    
    % Write the whole formula string
    if ~isempty(obj.formulaString)
        fprintf(obj.fileID, obj.formulaString);
    end
    
    % Write the SMT subrequirements
    fprintf(obj.fileID,'# =========== SUBREQUIREMENTS ============\n');
    if length(FPIstruct) == 1
        fprintf(obj.fileID, '# No prerequisites!\n');
        fprintf(obj.fileID, ['# phi_sub1 := ' FPIstruct(1).formula '\n\n']);
    else
        for kk = 1:length(FPIstruct)
            fprintf(obj.fileID, ['# Prerequisite ' num2str(kk) ' #\n']);
            % Remove identical entries coming from
            % different switches
            FPIstruct(kk).prereqSignals = unique(FPIstruct(kk).prereqSignals);
            try
                prereqSignals = FPIstruct(kk).prereqSignals{1};
            catch
                % prereqSignals is empty
                prereqSignals = '';
            end
            for kpr = 2:length(FPIstruct(kk).prereqSignals)
                prereqSignals = [prereqSignals ', ' FPIstruct(kk).prereqSignals{kpr}]; %#ok<AGROW>
            end
            fprintf(obj.fileID, ['# ' prereqSignals '\n']);
            
            fprintf(obj.fileID, ['# prereq' num2str(kk) ' := ' FPIstruct(kk).prereqFormula '\n']);
            fprintf(obj.fileID, ['# phi_sub' num2str(kk) ' := ' FPIstruct(kk).formula '\n\n']);
        end
    end
    
    fprintf(obj.fileID,'# =========== FINAL REQUIREMENT ===========\n');
    
    % First, write the version of the requirement where we interpret
    % switches with "=>"
    fprintf(obj.fileID, '# phi_implies is the formula when interpreting switches using "=>"\n');
    
    if length(FPIstruct) == 1
        fprintf(obj.fileID, ['# phi_implies := ' FPIstruct(1).formula '\n\n']);
    else
        fprintf(obj.fileID, '# phi_implies := ');
        for kk = 1:length(FPIstruct)-1
            fprintf(obj.fileID, ['(' FPIstruct(kk).prereqFormula ' => ' FPIstruct(kk).formula ') and ']);
        end
        % Write the final prereq and formula
        fprintf(obj.fileID, ['(' FPIstruct(end).prereqFormula ' => ' FPIstruct(end).formula ')\n\n']);
    end
    
    % Create "init"-time
    if startDelay == 0
        initTimeString = 't_init';
    else
        initTimeString = ['t_init + ' num2str(startDelay) '*dt'];
    end
    
    % Create end-time
    if endDelay == 0
        endTimeString = 't_final';
    else
        endTimeString = ['t_final - ' num2str(endDelay) '*dt'];
    end
    
    if length(FPIstruct) == 1
        if strcmp(obj.specType, 'safety')
            fprintf(obj.fileID, ['phi_' obj.requirement ' := alw_[' initTimeString ',' endTimeString '](' FPIstruct(1).formula ')\n\n']);
        elseif strcmp(obj.specType, 'activation')
            fprintf(obj.fileID, ['phi_' obj.requirement ' := alw_[' initTimeString ',' endTimeString '](not(' FPIstruct(1).formula '))\n\n']);
        elseif strcmp(obj.specType, 'none')
            fprintf(obj.fileID, ['phi_' obj.requirement ' := ' FPIstruct(1).formula '\n\n']);
        else
            error('Unknown requirement type (not safety or none)');
        end
    else
        if strcmp(obj.specType, 'safety')
            fprintf(obj.fileID, [obj.requirement ' := alw_[' initTimeString ',' endTimeString '](']);
        elseif strcmp(obj.specType, 'activation')
            fprintf(obj.fileID, [obj.requirement ' := alw_[' initTimeString ',' endTimeString '](not(']);
        elseif strcmp(obj.specType, 'none')
            fprintf(obj.fileID, [obj.requirement ' := ' FPIstruct(1).formula '\n\n']);
        else
            error('Unknown requirement type (not safety or none)');
        end
        
        for kk = 1:length(FPIstruct)-1
            fprintf(obj.fileID, ['(' FPIstruct(kk).prereqFormula ' and ' FPIstruct(kk).formula ') or ']);
        end
        
        
        % Write the final prereq and formula
        if strcmp(obj.specType, 'safety')
            fprintf(obj.fileID, ['(' FPIstruct(end).prereqFormula ' and ' FPIstruct(end).formula '))\n\n']);
        elseif strcmp(obj.specType, 'activation')
            fprintf(obj.fileID, ['(' FPIstruct(end).prereqFormula ' and ' FPIstruct(end).formula ')))\n\n']);
        elseif strcmp(obj.specType, 'none')
            fprintf(obj.fileID, ['(' FPIstruct(end).prereqFormula ' and ' FPIstruct(end).formula ')\n\n']);
        else
            error('Unknown requirement type (not safety or none)');
        end
    end
    fclose(obj.fileID);
    
    %if length(str) > obj.charLimit
    if false
        % The STL formula is too long!
        if ~isdir([obj.resultsFolder '/TooLong'])
            mkdir([obj.resultsFolder '/TooLong']);
        end
        
        % Move the file into TooLong directory
        movefile([resultsFolder '/' filename '.stl'],[resultsFolder '/TooLong/' filename '.stl']);
        
        obj.tooLongSTLFormula = 1;
    end
    
end

end



