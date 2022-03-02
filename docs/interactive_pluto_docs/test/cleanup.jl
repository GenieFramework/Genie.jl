function cleanup()
    try
        if isdir("PlutoNotebooks/180--Working_With_Genie_Apps/MyGenieApp")
            rm("PlutoNotebooks/180--Working_With_Genie_Apps/MyGenieApp", recursive=true)
        end
        
        if isdir("PlutoNotebooks/41--Developing_MVC_Web_Apps/Watchtonight/")
            rm("PlutoNotebooks/41--Developing_MVC_Web_Apps/Watchtonight/", recursive=true)
        end

        if isdir("PlutoNotebooks/9--Publishing_Your_Julia_Code_Online_With_Genie_Apps/MyGenieApp")
            rm("PlutoNotebooks/9--Publishing_Your_Julia_Code_Online_With_Genie_Apps/MyGenieApp", recursive=true)
        end

        if isdir("PlutoNotebooks/4--Developing_Web_Services/MyGenieApp")
            rm("PlutoNotebooks/4--Developing_Web_Services/MyGenieApp", recursive=true)
        end
    catch
        print("cleanup failed")
    end
end

cleanup()