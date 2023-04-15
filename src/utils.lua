-- -- Usage :
-- local folder_path = "/chemin/vers/votre/dossier"
-- local prefix = "frame_"
-- delete_files_with_prefix(folder_path, prefix)

function delete_files_with_prefix(folder_path, prefix)
  local command
  if package.config:sub(1,1) == '\\' then
    -- Windows system
    command = string.format('del /Q /F "%s\\%s*"', folder_path, prefix)
  else
    -- Unix-based system (Linux or macOS)
    command = string.format('rm -f "%s"/%s*', folder_path, prefix)
  end

  os.execute(command)
end

-- -- Usage :
-- local folder_path = "/chemin/vers/votre/dossier"
-- local zip_path = "/chemin/vers/le/fichier/zip/output.zip"
-- compress_folder_to_zip(folder_path, zip_path)
function file_exists(file_path)
  local file = io.open(file_path, "r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

function remove_file(file_path)
  local command
  if package.config:sub(1,1) == '\\' then
    -- Windows system
    command = string.format('del /Q /F "%s"', file_path)
  else
    -- Unix-based system (Linux or macOS)
    command = string.format('rm -f "%s"', file_path)
  end

  os.execute(command)
end

function compress_folder_to_zip(folder_path, zip_path)
  if file_exists(zip_path) then
    remove_file(zip_path)
  end

  local command
  if package.config:sub(1,1) == '\\' then
    -- Windows system
    command = string.format('powershell -command "Compress-Archive -Path \'%s\\*\' -DestinationPath \'%s\'"', folder_path, zip_path)
  else
    -- Unix-based system (Linux or macOS)
    command = string.format('zip -r "%s" "%s"', zip_path, folder_path)
  end

  os.execute(command)
end