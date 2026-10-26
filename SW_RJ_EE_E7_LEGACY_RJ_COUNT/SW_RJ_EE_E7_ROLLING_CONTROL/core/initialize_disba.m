function  initialize_disba
% 验证 Python 版本
pe = pyenv;
disp(['Python 版本: ', char(pe.Version)]);
disp(['Python 可执行文件: ', pe.Executable]);

% 确保 Python 环境正确
try
    py.importlib.import_module('disba');
    py.importlib.import_module('numpy');
    disp('disba 模块成功导入');
catch
    warning('无法导入 disba 模块，请检查 Python 环境和安装');
    return;
end

end