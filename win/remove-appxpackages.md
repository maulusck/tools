## As per KB Article 2769827, run the following command to get the exact package name:
```
Get-AppxPackage -AllUser | Format-List -Property PackageFullName,PackageUserInformation.
```
## After that, run one of the following command to remove the package or provision package.
```
Run Remove-AppxPackage -Package <packagefullname>
```
## Remove the provisioning by running the following cmdlet:
```
Remove-AppxProvisionedPackage -Online -PackageName <packagefullname>
```