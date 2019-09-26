using System.Linq;
using System.Management.Automation;
using System.Reflection;

namespace Acklann.Ncrement.Cmdlets
{
    /// <summary>
    /// </summary>
    /// <seealso cref="System.Management.Automation.Cmdlet" />
    /// <seealso cref="Acklann.Ncrement.IManifest" />
    public abstract class CmdletBase : Cmdlet, IManifest
    {
        /// <summary>
        /// <para type="description">The manifest ID.</para>
        /// </summary>
        [Parameter]
        public string Id { get; set; }

        /// <summary>
        /// <para type="description">The manifest name.</para>
        /// </summary>
        [Parameter]
        [Alias("Title")]
        public string Name { get; set; }

        /// <summary>
        /// <para type="description">The manifest version.</para>
        /// </summary>
        [Parameter]
        [Alias("v", "ver")]
        public string Version { get; set; }

        /// <summary>
        /// <para type="description">The manifest version format.</para>
        /// </summary>
        [Parameter]
        public string VersionFormat { get; set; }

        /// <summary>
        /// <para type="description">The manifest description.</para>
        /// </summary>
        [Parameter]
        public string Description { get; set; }

        /// <summary>
        /// <para type="description">The manifest tags.</para>
        /// </summary>
        [Parameter]
        public string Tags { get; set; }

        /// <summary>
        /// <para type="description">The manifest project url.</para>
        /// </summary>
        [Parameter]
        public string Website { get; set; }

        /// <summary>
        /// <para type="description">The manifest icon uri.</para>
        /// </summary>
        [Parameter]
        public string Icon { get; set; }

        /// <summary>
        /// <para type="description">The manifest repository uri.</para>
        /// </summary>
        [Parameter]
        public string Repository { get; set; }

        /// <summary>
        /// <para type="description">The manifest release notes.</para>
        /// </summary>
        [Parameter]
        public string ReleaseNotes { get; set; }

        /// <summary>
        /// <para type="description">The manifest company.</para>
        /// </summary>
        [Parameter]
        public string Company { get; set; }

        /// <summary>
        /// <para type="description">The manifest authors.</para>
        /// </summary>
        [Parameter]
        public string Authors { get; set; }

        /// <summary>
        /// <para type="description">The manifest license.</para>
        /// </summary>
        [Parameter]
        public string License { get; set; }

        /// <summary>
        /// <para type="description">The manifest copyright.</para>
        /// </summary>
        [Parameter]
        public string Copyright { get; set; }

        /// <summary>
        /// Overwrites the specified manifest.
        /// </summary>
        /// <param name="manifest">The manifest.</param>
        /// <returns></returns>
        protected internal Manifest Overwrite(Manifest manifest)
        {
            var cmdletProperties = from x in typeof(CmdletBase).GetMembers()
                                   where
                                    x.MemberType == MemberTypes.Property
                                    &&
                                    x.IsDefined(typeof(ParameterAttribute))
                                   let prop = x as PropertyInfo
                                   where prop.GetValue(this) != null
                                   select prop;

            var manifestProperties = from x in typeof(Manifest).GetMembers()
                                     where x.MemberType == MemberTypes.Property
                                     select (x as PropertyInfo);

            foreach (PropertyInfo cp in cmdletProperties)
                foreach (PropertyInfo mp in manifestProperties)
                    if (mp.Name == cp.Name)
                    {
                        mp.SetValue(manifest, cp.GetValue(this));
                        break;
                    }

            return manifest;
        }
    }
}