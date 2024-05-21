#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS buildimage
WORKDIR /src
COPY ["MT3Chained-Web.csproj", "."]
RUN dotnet restore "./MT3Chained-Web.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet publish "MT3Chained-Web.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS runtimeonlyimage
WORKDIR /app
EXPOSE 80
# Install Curl
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y curl

FROM runtimeonlyimage AS final
WORKDIR /app
COPY --from=buildimage /app/publish .
ENTRYPOINT ["dotnet", "MT3Chained-Web.dll"]