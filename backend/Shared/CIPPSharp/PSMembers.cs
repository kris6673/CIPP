using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Management.Automation;
using System.Reflection;

namespace CIPP
{
    // Enumerating PSObject.Properties builds reserved member sets and caches that stay attached to every row (~3 KB each).
    internal static class PSMembers
    {
        private static readonly Func<object, IEnumerable<PSMemberInfo>?>? s_instanceMembers = Build();
        // Enumerating Properties once adds the reserved pstypenames to the instance members, marked hidden.
        private static readonly Func<PSMemberInfo, bool>? s_isHidden = BuildIsHidden();

        private static Func<PSMemberInfo, bool>? BuildIsHidden()
        {
            try
            {
                var property = typeof(PSMemberInfo).GetProperty("IsHidden", BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance);
                if (property == null || property.PropertyType != typeof(bool)) return null;
                var member = Expression.Parameter(typeof(PSMemberInfo));
                return Expression.Lambda<Func<PSMemberInfo, bool>>(Expression.Property(member, property), member).Compile();
            }
            catch { return null; }
        }

        private static Func<object, IEnumerable<PSMemberInfo>?>? Build()
        {
            try
            {
                var method = typeof(PSObject).GetMethod("HasInstanceMembers", BindingFlags.NonPublic | BindingFlags.Static);
                if (method == null) return null;
                var parameters = method.GetParameters();
                if (parameters.Length != 2 || !parameters[1].ParameterType.IsByRef) return null;
                var collectionType = parameters[1].ParameterType.GetElementType()!;
                if (!typeof(IEnumerable<PSMemberInfo>).IsAssignableFrom(collectionType)) return null;

                var obj = Expression.Parameter(typeof(object));
                var members = Expression.Variable(collectionType);
                var body = Expression.Block(new[] { members },
                    Expression.Condition(Expression.Call(method, obj, members),
                        Expression.Convert(members, typeof(IEnumerable<PSMemberInfo>)),
                        Expression.Constant(null, typeof(IEnumerable<PSMemberInfo>))));
                return Expression.Lambda<Func<object, IEnumerable<PSMemberInfo>?>>(body, obj).Compile();
            }
            catch { return null; }
        }

        public static bool Available => s_instanceMembers != null && s_isHidden != null;

        // Added properties only: adapted .NET properties of a wrapped value are not included.
        public static IEnumerable<PSPropertyInfo> InstanceProperties(PSObject pso)
        {
            var members = s_instanceMembers!(pso);
            if (members == null) yield break;
            foreach (var m in members)
                if (m is PSPropertyInfo p && !s_isHidden!(p)) yield return p;
        }

        public static bool HasNoteProperty(PSObject pso)
        {
            var members = s_instanceMembers!(pso);
            if (members == null) return false;
            foreach (var m in members)
                if (m is PSNoteProperty && !s_isHidden!(m)) return true;
            return false;
        }
    }
}
