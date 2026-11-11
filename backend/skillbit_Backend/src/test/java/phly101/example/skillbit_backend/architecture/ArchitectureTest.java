package phly101.example.skillbit_backend.architecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

@AnalyzeClasses(packages = "phly101.example.skillbit_backend", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

    @ArchTest
    static final ArchRule controllers_do_not_use_repositories = noClasses().that().resideInAPackage("..web..")
            .should().dependOnClassesThat().resideInAPackage("..repository..")
            .because("Controllers should not access repositories directly, they should use services instead.");

    @ArchTest
    static final ArchRule dto_and_web_must_not_depend_on_domain = noClasses().that()
            .resideInAnyPackage("..web..", "..dto..")
            .should().dependOnClassesThat().resideInAPackage("..domain..")
            .because("DTOs and web layers must not depend on domain layers.");

    @ArchTest
    static final ArchRule services_must_not_depend_on_web = noClasses().that().resideInAPackage("..service..")
            .should().dependOnClassesThat().resideInAPackage("..web..")
            .because("Services should not depend on web layers.");

    @ArchTest
    static final ArchRule no_cycles_between_modules = slices()
            .matching("phly101.example.skillbit_backend.(*)..").should().beFreeOfCycles()
            .because("There should be no cyclic dependencies between modules.");


            @ArchTest static final ArchRule common_must_not_depend_on_feature_modules = 
            noClasses().that().resideInAPackage("..common..")
            .should().dependOnClassesThat().resideInAnyPackage("phly101.example.skillbit_backend.auth",
                "phly101.example.skillbit_backend.achievement",
                "phly101.example.skillbit_backend.contest",
                "phly101.example.skillbit_backend.examples",
                "phly101.example.skillbit_backend.friendlymatches",
                "phly101.example.skillbit_backend.learning",
                "phly101.example.skillbit_backend.question",
                "phly101.example.skillbit_backend.realtime",
                "phly101.example.skillbit_backend.quiz",
                "phly101.example.skillbit_backend.user",
                "phly101.example.skillbit_backend.social",
                "phly101.example.skillbit_backend.scoring",
                "phly101.example.skillbit_backend.admin"
            )
            .because("Common packages must not depend on any other packages.");}